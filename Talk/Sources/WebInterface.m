//
//  WebInterface.m
//  Talk
//
//  Created by Cornelis van der Bent on 9/9/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//
//  The server list is DNS-refreshed when it's empty, when the shortest TTL of
//  all servers has expired, or when one of the servers returned a failure;
//  so not when HTTPS request timed out for example).  The code below adds
//  60 seconds to the expiry time to make sure that our refresh is well after
//  the TTL has expired; this to make sure we get fresh values from iOS' DNS
//  cache.
//
//  The new list of servers is tested.  Servers that fail, are removed from
//  the list; they get a new chance on the next refresh.
//
//  The sequence in which the servers are used for API calls, is determined
//  by their DNS SRV priority and weight.  Only the highest priority servers
//  will be used.  Subsequently these highest priority servers will be used
//  in weighted round-robin fashion.
//
//  The round-robin scheme works as follows: A so called 'weighter' value is
//  incremented with the GCD of weights of the servers with highest priority.
//  Image the weights of the used servers are lined up along a line that has
//  a length of weightSum.  Then imagine a parallel line with a length equal
//  to weighter % weighterSum (which is less than weighterSum).  This line
//  ends at one of the server's weights, which is the server that is selected.
//  Finally the weighter is incremented with weighterIncrement (which is, as
//  said, the GCD of the weights).
//

#import <objc/runtime.h>
#import <dns_sd.h>
#import <dns_util.h>
#import "WebInterface.h"
#import "Common.h"
#import "Settings.h"
#import "AFNetworking.h"


@interface WebInterface ()

@property (nonatomic, assign) NSTimeInterval  dnsUpdateTimeout; // Seconds.
@property (nonatomic, strong) NSDate*         dnsUpdateDate;
@property (atomic, assign)    uint32_t        ttl;              // Shortest TTL of servers, in seconds.
@property (nonatomic, strong) NSMutableArray* servers;
@property (nonatomic, strong) NSMutableArray* updatingServers;
@property (nonatomic, assign) int             weightSum;
@property (nonatomic, assign) int             weighter;
@property (nonatomic, assign) int             weighterIncrement;

@end


@implementation WebInterface

+ (WebInterface*)sharedInterface
{
    static WebInterface*   sharedInstance;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^
    {
        sharedInstance = [[WebInterface alloc] init];

        sharedInstance.dnsUpdateTimeout   = 20;
        sharedInstance.requestSerializer  = [AFJSONRequestSerializer serializer];
        [sharedInstance.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [sharedInstance.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

        sharedInstance.responseSerializer = [AFJSONResponseSerializer serializer];

        [sharedInstance.operationQueue setMaxConcurrentOperationCount:10];

        sharedInstance.securityPolicy.allowInvalidCertificates = NO;
    });
    
    return sharedInstance;
}


- (void)updateServers
{
    // Allow only one thread to update the server list.
    @synchronized(self)
    {
        if (self.servers.count == 0 || [[NSDate date] timeIntervalSinceDate:self.dnsUpdateDate] > (self.ttl + 60))
        {
            self.updatingServers = [NSMutableArray array];
            self.ttl             = UINT32_MAX;

            NBLog(@"Start DNS update.");
            DNSServiceRef       sdRef;
            DNSServiceErrorType error;

            const char* host = [[Settings sharedSettings].dnsHost UTF8String];
            if (host != NULL)
            {
                NSTimeInterval remainingTime = self.dnsUpdateTimeout;
                NSDate*        startTime     = [NSDate date];

                error = DNSServiceQueryRecord(&sdRef,
                                              0,
                                              0,
                                              host,
                                              kDNSServiceType_SRV,
                                              kDNSServiceClass_IN,
                                              processDnsReply,
                                              &remainingTime);

                if (error != kDNSServiceErr_NoError)
                {
                    NBLog(@"DNS SRV query failed: %d.", error);

                    goto done;
                }

                // This is necessary so we don't hang forever if there are no results
                int    dns_sd_fd = DNSServiceRefSockFD(sdRef);
                int    nfds      = dns_sd_fd + 1;
                fd_set readfds;
                int    result;

                while (remainingTime > 0)
                {
                    FD_ZERO(&readfds);
                    FD_SET(dns_sd_fd, &readfds);

                    struct timeval tv;
                    tv.tv_sec  = (time_t)remainingTime;
                    tv.tv_usec = (remainingTime - tv.tv_sec) * 1000000;

                    result = select(nfds, &readfds, (fd_set*)NULL, (fd_set*)NULL, &tv);
                    if (result == 1)
                    {
                        if (FD_ISSET(dns_sd_fd, &readfds))
                        {
                            error = DNSServiceProcessResult(sdRef);
                            if (error != kDNSServiceErr_NoError)
                            {
                                NBLog(@"There was an error reading the DNS SRV records.");
                                break;
                            }
                        }
                    }
                    else if (result == 0)
                    {
                        NBLog(@"DNS SRV select() timed out");
                        remainingTime = DBL_MIN;
                        break;
                    }
                    else
                    {
                        if (errno == EINTR)
                        {
                            NBLog(@"DNS SRV select() interrupted, retry.");
                        }
                        else
                        {
                            NBLog(@"DNS SRV select() returned %d errno %d %s.", result, errno, strerror(errno));
                            remainingTime = DBL_MIN;
                            break;
                        }
                    }

                    if (remainingTime > 0)
                    {
                        NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:startTime];
                        remainingTime -= elapsed;
                    }
                }
                
                if (remainingTime == DBL_MIN)
                {
                    NBLog(@"DNS update failed.");
                }
                else if (remainingTime <= 0)
                {
                    NBLog(@"DNS update done.");

                    self.servers = self.updatingServers;

                    [self testServers];
                    [self prepareServers];
                }
                else
                {
                    NBLog(@"DNS: This can't happen.");
                }
                
                DNSServiceRefDeallocate(sdRef);
            }
        }

    done:
        if (self.servers.count == 0)
        {
            NSDictionary* server = @{@"target"   : [Settings sharedSettings].defaultServer,
                                     @"priority" : @(1),
                                     @"weight"   : @(100),
                                     @"ttl"      : @(1800)};
            self.servers   = [NSMutableArray arrayWithObject:server];
            self.weightSum = 100;
        }
    }
}


static void processDnsReply(DNSServiceRef       sdRef,
                            DNSServiceFlags     flags,
                            uint32_t            interfaceIndex,
                            DNSServiceErrorType errorCode,
                            const char*         fullname,
                            uint16_t            rrtype,
                            uint16_t            rrclass,
                            uint16_t            rdlen,
                            const void*         rdata,
                            uint32_t            ttl,
                            void*               context)
{
    NSTimeInterval* remainingTime = (NSTimeInterval*)context;

    //  If a timeout occurs the value of the errorCode argument will be
    //  kDNSServiceErr_Timeout.
    if (errorCode != kDNSServiceErr_NoError)
    {
        return;
    }

    // If the last record is being passed, the kDNSServiceFlagsMoreComing
    // flag is cleared.  When this is the case, inform updateDnsRecords.
    if ((flags & kDNSServiceFlagsMoreComing) == 0)
    {
        *remainingTime = 0;
    }

    //  The flags argument will have the kDNSServiceFlagsAdd bit set if the
    //  callback is being invoked when a record is received in response to
    //  the query.
    //
    //  If kDNSServiceFlagsAdd bit is clear then callback is being invoked
    //  because the record has expired, in which case the ttl argument will
    //  be 0.
    if ((flags & kDNSServiceFlagsAdd) == 0)
    {
        // Because we build up a new list of servers, we can simply ignore
        // the ones that are deleted.
        return;
    }

    // Record parsing code below was copied from Apple SRVResolver sample.
    NSMutableData*         rrData = [NSMutableData data];
    dns_resource_record_t* rr;
    uint8_t                u8;
    uint16_t               u16;
    uint32_t               u32;

    // Create full RR record; this function only gets the data part as byte array.
    u8 = 0;
    [rrData appendBytes:&u8 length:sizeof(u8)];
    u16 = htons(kDNSServiceType_SRV);
    [rrData appendBytes:&u16 length:sizeof(u16)];
    u16 = htons(kDNSServiceClass_IN);
    [rrData appendBytes:&u16 length:sizeof(u16)];
    u32 = htonl(ttl);
    [rrData appendBytes:&u32 length:sizeof(u32)];
    u16 = htons(rdlen);
    [rrData appendBytes:&u16 length:sizeof(u16)];
    [rrData appendBytes:rdata length:rdlen];

    // Now that we have a full RR record, we can use the DNS Util parse function.
    rr = dns_parse_resource_record([rrData bytes], (uint32_t) [rrData length]);

    // If the parse is successful, add the results.
    if (rr != NULL)
    {
        NSString* target = [NSString stringWithCString:rr->data.SRV->target encoding:NSASCIIStringEncoding];
        if (target != nil)
        {
            [WebInterface sharedInterface].ttl = MIN([WebInterface sharedInterface].ttl, ttl);

            uint16_t port     = rr->data.SRV->port;
            uint16_t priority = rr->data.SRV->priority;
            uint16_t weight   = rr->data.SRV->weight;

            NSDictionary* server = @{@"target"   : target,
                                     @"port"     : @(port),
                                     @"priority" : @(priority),
                                     @"weight"   : @(weight),
                                     @"ttl"      : @(ttl)};

            [[WebInterface sharedInterface].updatingServers addObject:server];
        }
    }
    else
    {
        // Notify updateDnsRecords that something went wrong.
        *remainingTime = DBL_MIN;
    }
    
    dns_free_resource_record(rr);
}


- (void)testServers
{
    NSMutableArray* testServers = [NSMutableArray array];

    for (NSDictionary* server in self.servers)
    {
        NSString* urlString = [NSString stringWithFormat:@"https://%@:%d%@",
                                                         server[@"target"],
                                                         [server[@"port"] intValue],
                                                         [Settings sharedSettings].serverTestUrlPath];

        NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString] options:NSDataReadingUncached
                                               error:nil];
        if (data != nil && [[Common objectWithJsonData:data][@"status"] isEqualToString:@"OK"])
        {
            [testServers addObject:server];
        }
    }

    self.servers = testServers;
}


- (void)prepareServers
{
    if (self.servers.count == 0)
    {
        NBLog(@"No DNS-SRV servers to prepare.");

        return;
    }

    // Sort servers in descending priority order.
    [self.servers sortUsingComparator:^NSComparisonResult(NSDictionary* server1, NSDictionary* server2)
    {
        return [server1[@"priority"] intValue] > [server2[@"priority"] intValue];
    }];

    self.weightSum = 0;
    int weightMin = INT_MAX;
    int priority = [self.servers[0][@"priority"] intValue];
    for (NSDictionary* server in self.servers)
    {
        if ([server[@"priority"] intValue] == priority)
        {
            int weight = [server[@"weight"] intValue];
            self.weightSum += weight;

            weightMin = MIN(weightMin, weight);
        }
    }

    // Find weightIncrement as GCD of all weights.
    self.weighterIncrement = 1;
    for (int divisor = 2; divisor <= weightMin; divisor++)
    {
        BOOL isDivisor;
        for (NSDictionary* server in self.servers)
        {
            int weight = [server[@"weight"] intValue];
            isDivisor = (weight % divisor) == 0;

            if (isDivisor == NO)
            {
                break;
            }
        }

        if (isDivisor)
        {
            self.weighterIncrement = divisor;
        }
    }
}


- (NSDictionary*)selectServer
{
    [self updateServers];

    int           priority = [self.servers[0][@"priority"] intValue];
    NSDictionary* server = nil;

    int weighter = 0;
    for (server in self.servers)
    {
        if ([server[@"priority"] intValue] == priority)
        {
            weighter += [server[@"weight"] intValue];

            if ((self.weighter % self.weightSum) < weighter)
            {
                break;
            }
        }
    }

    self.weighter += self.weighterIncrement;

    return server;
}


#pragma mark WebClient mapping methods

- (AFHTTPRequestOperation*)RequestOperationWithRequest:(NSURLRequest*)request
                                               success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success
                                               failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure
{
    AFHTTPRequestOperation* operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];

    operation.responseSerializer = self.responseSerializer;
    [operation setResponseSerializer:[AFJSONResponseSerializer serializer]]; // force json response serializer
    operation.shouldUseCredentialStorage = self.shouldUseCredentialStorage;
    operation.credential                 = self.credential;
    operation.securityPolicy             = self.securityPolicy;

    [operation setCompletionBlockWithSuccess:success failure:failure];
    operation.completionQueue = self.completionQueue;
    operation.completionGroup = self.completionGroup;
    
    return operation;
}


- (void)requestWithMethod:(NSString*)method
                     path:(NSString*)path
               parameters:(id)parameters
                  success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success
                  failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^
    {
        [self.requestSerializer setAuthorizationHeaderFieldWithUsername:[self.delegate webUsername]
                                                               password:[self.delegate webPassword]];

        NSDictionary* server    = [self selectServer];
        NSString*     urlString = [NSString stringWithFormat:@"https://%@:%d%@",
                                                             server[@"target"],
                                                             [server[@"port"] intValue],
                                                             path];
        NSMutableURLRequest* request = [self.requestSerializer requestWithMethod:method
                                                                         URLString:urlString
                                                                        parameters:parameters
                                                                             error:nil];    //### Is 'nil' okay?

        AFHTTPRequestOperation* operation = [self RequestOperationWithRequest:request success:success failure:failure];

        [self.operationQueue addOperation:operation];
    });
}


- (void)getPath:(NSString*)path
     parameters:(id)parameters
        success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success
        failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure
{
    [self requestWithMethod:@"GET" path:path parameters:parameters success:success failure:failure];
}


- (void)postPath:(NSString*)path
      parameters:(id)parameters
         success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success
         failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure
{
    [self requestWithMethod:@"POST" path:path parameters:parameters success:success failure:failure];
}


- (void)putPath:(NSString*)path
     parameters:(id)parameters
        success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success
        failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure
{
    [self requestWithMethod:@"PUT" path:path parameters:parameters success:success failure:failure];
}


- (void)deletePath:(NSString*)path
        parameters:(id)parameters
           success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success
           failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure
{
    [self requestWithMethod:@"DELETE" path:path parameters:parameters success:success failure:failure];
}


- (void)cancelAllHttpOperationsWithMethod:(NSString*)method path:(NSString*)path
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^
    {
        for (AFHTTPRequestOperation* operation in self.operationQueue.operations)
        {
            if ([operation.request.HTTPMethod isEqualToString:method] &&
                [operation.request.URL.path   isEqualToString:path])
            {
                NBLog(@"Cancelling HTTP %@ %@", method, path);
                [operation cancel];
            }
        }
    });
}


- (void)cancelAllHttpOperations
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^
    {
        for (AFHTTPRequestOperation* operation in self.operationQueue.operations)
        {
            [operation cancel];
        }
    });
}

@end
