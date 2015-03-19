//
//  FailoverWebInterface.m
//  Talk
//
//  Created by Dev on 9/9/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//
//  Apple's sample SRV resolver: https://developer.apple.com/library/mac/samplecode/SRVResolver/Introduction/Intro.html
//

#import <objc/runtime.h>
#import <dns_sd.h>
#import <dns_util.h>
#import "FailoverWebInterface.h"
#import "AFNetworking.h"
#import "RetryRequest.h"


@interface FailoverWebInterface ()

@property (nonatomic, assign) int             okStep;
@property (nonatomic, assign) int             failStep;
@property (nonatomic, assign) NSTimeInterval  dnsUpdateTimeout; // Seconds.
@property (atomic, assign)    uint32_t        ttl;              // Seconds.
@property (atomic, strong)    NSDate*         dnsUpdateDate;
@property (atomic, assign)    BOOL            dnsUpdatePending;
@property (atomic, strong)    NSMutableArray* serversQueue;
@property (atomic, strong)    NSMutableArray* fetchedServers;

@end


@implementation FailoverWebInterface

+ (FailoverWebInterface*)sharedInterface
{
    static FailoverWebInterface* sharedInstance;
    static dispatch_once_t       onceToken;

    dispatch_once(&onceToken, ^
    {
        sharedInstance = [[FailoverWebInterface alloc] init];

        sharedInstance.okStep             =  1;
        sharedInstance.failStep           =  3;
        sharedInstance.timeout            = 20;
        sharedInstance.retries            =  2;
        sharedInstance.delay              =  0.25;
        sharedInstance.serversQueue       = [NSMutableArray new];
        sharedInstance.fetchedServers     = [NSMutableArray new];
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


- (void)checkDnsRecords
{
    if (self.serversQueue.count == 0)
    {
        [self updateDnsRecords];
    }
    else if ([[NSDate date] timeIntervalSinceDate:self.dnsUpdateDate] > self.ttl)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^
        {
            [self updateDnsRecords];
        });
    }
}


// TODO Implement flushing cache: https://developer.apple.com/library/mac/documentation/Networking/Conceptual/NSNetServiceProgGuide/Articles/ResolvingServices.html DNSServiceReconfirmRecord
- (void)updateDnsRecords
{
    if (self.dnsUpdatePending == YES)
    {
        return;
    }
    else
    {
        self.dnsUpdatePending = YES;
        [self.fetchedServers removeAllObjects];
    }

    NBLog(@"Start DNS update.");
    DNSServiceRef       sdRef;
    DNSServiceErrorType err;

    const char* host = [self.dnsHost UTF8String];
    if (host != NULL)
    {
        NSTimeInterval remainingTime = self.dnsUpdateTimeout;
        NSDate*        startTime = [NSDate date];

        err = DNSServiceQueryRecord(&sdRef, 0, 0,
                                    host,
                                    kDNSServiceType_SRV,
                                    kDNSServiceClass_IN,
                                    processDnsReply,
                                    &remainingTime);

        if (err != kDNSServiceErr_NoError)
        {
            NBLog(@"DNS SRV query failed: %d", err);

            return;
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
                    err = DNSServiceProcessResult(sdRef);
                    if (err != kDNSServiceErr_NoError)
                    {
                        NBLog(@"There was an error reading the DNS SRV records.");
                        break;
                    }
                }
            }
            else if (result == 0)
            {
                NBLog(@"DNS SRV select() timed out");
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
                    break;
                }
            }

            if (remainingTime > 0)
            {
                NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:startTime];
                remainingTime -= elapsed;
            }
        }

        if (remainingTime == 0)
        {
            NBLog(@"DNS update done.");
            [self replaceServers];
        }
        else if (remainingTime == -1)
        {
            NBLog(@"Error parsing DNS data.");
        }
        else
        {
            NBLog(@"This can't happen.");
        }

        DNSServiceRefDeallocate(sdRef);
        self.dnsUpdatePending = NO;
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
            uint16_t priority = rr->data.SRV->priority;
            uint16_t weight   = rr->data.SRV->weight;
            uint16_t port     = rr->data.SRV->port;

            [[FailoverWebInterface sharedInterface] addServer:target priority:priority weight:weight port:port ttl:ttl];
        }
    }
    else
    {
        remainingTime = -1;
    }

    dns_free_resource_record(rr);
}


- (void)addServer:(NSString*)server
         priority:(uint16_t)priority
           weight:(uint16_t)weight
             port:(uint16_t)port
              ttl:(uint32_t)ttl
{
    if ([self.delegate respondsToSelector:@selector(modifyServer:)] == YES)
    {
        server = [self.delegate modifyServer:server];
    }

    NBLog(@">>> Service: %@ with Priority: %i", server, priority);

    NSPredicate*         predicate  = [NSPredicate predicateWithFormat:@"host == %@", server];
    NSMutableDictionary* info       = [[self.serversQueue filteredArrayUsingPredicate:predicate] firstObject];

    if (info != nil)
    {
        // Update existing.
        info[@"priority"] = @(priority);
        info[@"ttl"]      = @(ttl);
    }
    else
    {
        // New one.
        info = [@{@"host":server, @"order":@(priority), @"priority":@(priority), @"ttl":@(ttl)} mutableCopy];
    }

    [self.fetchedServers addObject:info];
}


- (void)replaceServers
{
    if (self.fetchedServers.count > 0)
    {
        self.ttl = INT_MAX;
        for (NSDictionary* info in self.fetchedServers)
        {
            self.ttl = MIN(self.ttl, [info[@"ttl"] intValue]);
        }

        self.dnsUpdateDate = [NSDate date];
        self.serversQueue  = self.fetchedServers;
    }

    [self.serversQueue sortUsingComparator:^(NSDictionary* info1, NSDictionary* info2)
    {
         if (info1[@"order"] > info2[@"order"])
         {
             return (NSComparisonResult)NSOrderedDescending;
         }
         else if (info1[@"order"] < info2[@"order"])
         {
             return (NSComparisonResult)NSOrderedAscending;
         }
         else
         {
             return (NSComparisonResult)NSOrderedSame;
         }
    }];

    self.failStep = self.serversQueue.count;
}


- (NSString*)getServer
{
    @synchronized(self)
    {
        if ([self.serversQueue count] > 0)
        {
            return [self.serversQueue[0][@"host"] copy];
        }
        else
        {
            return nil;
        }
    }
}


//update the server order by inserting the top server in a proper position
- (void)reorderServersWithSuccess:(BOOL)success
{
    @synchronized(self)
    {
        if ([self.serversQueue count] == 0)
        {
            return;
        }

        //pop the first server
        NSMutableDictionary* topserver = [self.serversQueue objectAtIndex:0];
        [self.serversQueue removeObjectAtIndex:0];

        int step = success ? self.okStep : self.failStep;
        topserver[@"order"] = @([topserver[@"order"] intValue] + [topserver[@"priority"] intValue] + step);

        int index = self.serversQueue.count;
        for (int i = 0; i < self.serversQueue.count; i++)
        {
            if ([topserver[@"order"] intValue] < [self.serversQueue[i][@"order"] intValue])
            {
                index = i;
                break;
            }
        }

        [self.serversQueue insertObject:topserver atIndex:index];
    }
}


- (void)networkRequestFail:(FailoverOperation*)notificationOperation
{
    NBLog(@"networkRequestFail");

    NSDictionary* headers = [(NSURLRequest*)notificationOperation.request allHTTPHeaderFields];
    if (![FailoverOperation hasIgnoreStartHeader:headers])
    {
        [notificationOperation cancel];
        
        NSURLRequest*        request        = notificationOperation.request;
        NSMutableURLRequest* mutableRequest = [request mutableCopy];
        [mutableRequest addValue:@"true" forHTTPHeaderField:@"IgnoreClientStartRetry"];
        request = [mutableRequest copy];

        FailoverOperation* operationCopy = [FailoverOperation operationWithOperation:notificationOperation
                                                                             request:request];
        
        [operationCopy setCompletionBlockWithSuccess:^(AFHTTPRequestOperation* operation, id responseObject)
        {
            FailoverOperation* operationFailover = (FailoverOperation*)operation;
            operationFailover.success(operation, responseObject);
        }
                                             failure:^(AFHTTPRequestOperation* operation, NSError* error)
        {
            NSHTTPURLResponse* httpResponse = operation.response;

            if (httpResponse.statusCode / 100 == 4)// failure considered, so start the retry algorithm
            {
                NBLog(@"%@: Retry triggered at:%@", operation.request.URL, [NSDate new]);

                RetryRequest* retry = [RetryRequest new];

                // run retry algorithm
                [retry tryMakeRequest:operation];
            }
            else
            {
                FailoverOperation* operationFailover = (FailoverOperation*)operation;
                operationFailover.failure(operation, error);
            }
        }];
        
        [[self operationQueue] addOperation:operationCopy];
    }
}


#pragma mark WebClient mapping methods

- (FailoverOperation*)failoverOperationWithRequest:(NSURLRequest*)request
                                           success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success
                                           failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure
{
    FailoverOperation* operation = [[FailoverOperation alloc] initWithRequest:request];

    operation.responseSerializer = self.responseSerializer;
    [operation setResponseSerializer:[AFJSONResponseSerializer serializer]]; // force json response serializer
    operation.shouldUseCredentialStorage = self.shouldUseCredentialStorage;
    operation.credential                 = self.credential;
    operation.securityPolicy             = self.securityPolicy;
    operation.startTime                  = [NSDate date];
    operation.serverStates               = [NSMutableDictionary dictionary];
    for (NSString* server in self.serversQueue)
    {
        operation.serverStates[server] = @(self.retries);
    }
    
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
        [self checkDnsRecords];

        [self.requestSerializer setAuthorizationHeaderFieldWithUsername:[self.delegate webUsername]
                                                               password:[self.delegate webPassword]];

        NSString* urlString = [NSString stringWithFormat:@"https://%@%@", [self getServer], path];
        NSMutableURLRequest* request   = [self.requestSerializer requestWithMethod:method
                                                                         URLString:urlString
                                                                        parameters:parameters
                                                                             error:nil];    //### Is 'nil' okay?

        FailoverOperation* operation = [self failoverOperationWithRequest:request success:success failure:failure];

        NSLog(@"%@", [operation.request.URL path]);
        operation.success = success;
        operation.failure = failure;
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


- (void)cancelAllHTTPOperationsWithMethod:(NSString*)method path:(NSString*)path
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^
    {
        for (FailoverOperation* operation in self.operationQueue.operations)
        {
            if ([operation.request.HTTPMethod isEqualToString:method] &&
                [operation.request.URL.path   isEqualToString:path])
            {
                NBLog(@"####### Cancelling operation");
                [operation cancel];
            }
        }
    });
}

@end
