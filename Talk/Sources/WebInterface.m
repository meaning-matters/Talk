//
//  WebInterface.m
//  Talk
//
//  Created by Cornelis van der Bent on 9/9/14.
//  Copyright (c) 2014 NumberBay Ltd. All rights reserved.
//
//  The server list is DNS-refreshed when it's empty, when the shortest TTL of
//  all servers has expired, or when one of the servers returned a failure;
//  so not when HTTPS request timed out for example).  The code below adds
//  `kTtlIncrement` seconds to the expiry time to make sure that our refresh
//  is well after the TTL has expired; this to make sure we get fresh values,
//  and not the previous from (iOS') DNS cache.
//
//  The new list of servers is tested.  Servers that fail, are removed from
//  the list; they get a new chance on the next refresh.
//
//  The sequence in which the servers are used for API calls, is determined
//  by their DNS SRV priority and weight.  Only the highest priority servers
//  will be used.  Subsequently these highest priority servers will be used
//  in weighted round-robin fashion.
//
//  However, to prevent API calls to potentially go to a different server
//  each time, a hold mechanism has been added: As long as subsequent calls
//  are done within `kSelectedServerHoldTime`, the same server is used.  If
//  a previous call is longer ago, the weighted round-robin scheme kicks in
//  to select the next server.
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
//  In case of a failure ...... TODO: ### Don't retry on cancelled HTTP reguest and
//  neither on HTTP timeout, ...
//

#import "WebInterface.h"
#import <dns_sd.h>
#import <dns_util.h>
#import "WebStatus.h"
#import "Common.h"
#import "Settings.h"
#import "AFNetworking.h"
#import "NetworkStatus.h"
#import "AnalyticsTransmitter.h"


const NSTimeInterval kDnsUpdateTimeoutReachable    =   4;  // Keep this low to switch to fallback server soon.
const NSTimeInterval kDnsUpdateTimeoutNotReachable =   2;  // Limit timeout because of hard `select()` timeout.
const NSTimeInterval kApiRequestTimeout            =  20;
const NSTimeInterval kTtlIncrement                 =  10;
const NSTimeInterval kSelectedServerHoldTime       =  10;
const uint32_t       kFallbackServerTtl            = 600;  // Retry to load DNS-SRV after an hour.


@interface WebInterface ()

@property (nonatomic, strong) NSDate*         dnsUpdateDate;
@property (atomic, assign)    uint32_t        ttl;              // Shortest TTL of servers, in seconds.
@property (nonatomic, strong) NSMutableArray* servers;
@property (nonatomic, assign) int             weightSum;
@property (nonatomic, assign) int             weighter;
@property (nonatomic, assign) int             weighterIncrement;
@property (nonatomic, strong) NSCondition*    condition;
@property (nonatomic, strong) NSDate*         selectedServerDate; // Date of last server selection.
@property (nonatomic, strong) NSDictionary*   selectedServer;

@end


@implementation WebInterface

+ (WebInterface*)sharedInterface
{
    static WebInterface*   sharedInstance;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^
    {
        sharedInstance = [[WebInterface alloc] init];

        sharedInstance.requestSerializer  = [AFJSONRequestSerializer serializer];
        [sharedInstance.requestSerializer setTimeoutInterval:kApiRequestTimeout];
        [sharedInstance.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [sharedInstance.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        // Switch off local caching.
       // [sharedInstance.requestSerializer setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];

        sharedInstance.responseSerializer = [AFJSONResponseSerializer serializer];

        sharedInstance.securityPolicy.allowInvalidCertificates = NO;
        
        sharedInstance.servers   = [NSMutableArray array];
        sharedInstance.condition = [[NSCondition alloc] init];
    });
    
    return sharedInstance;
}


- (void)updateServers
{
    // Allow only one thread to update the server list.
    @synchronized(self)  //### Is this thread-safe? However, `@synchronized(self.servers)` causes dead-lock in `testServers`.
    {
        if (self.servers.count == 0 ||
            [[NSDate date] timeIntervalSinceDate:self.dnsUpdateDate] > (self.ttl + kTtlIncrement) ||
            self.forceServerUpdate == YES)
        {
            self.forceServerUpdate = NO;
            
            @synchronized(self.servers)
            {
                [self.servers removeAllObjects];
                self.ttl = UINT32_MAX;
            }

            NBLog(@"Start DNS update.");
            DNSServiceRef       sdRef;
            DNSServiceErrorType error;

            const char*    host          = [[Settings sharedSettings].dnsSrvName UTF8String];
            NSDate*        startTime     = [NSDate date];
            NSTimeInterval remainingTime;
            if ([NetworkStatus sharedStatus].reachableStatus == NetworkStatusReachableWifi ||
                [NetworkStatus sharedStatus].reachableStatus == NetworkStatusReachableCellular)
            {
                remainingTime = kDnsUpdateTimeoutReachable;
            }
            else
            {
                remainingTime = kDnsUpdateTimeoutNotReachable;
            }

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
                
                if ([NetworkStatus sharedStatus].reachableStatus == NetworkStatusReachableWifi ||
                    [NetworkStatus sharedStatus].reachableStatus == NetworkStatusReachableCellular)
                {
                    self.dnsUpdateDate = [NSDate date];
                    [self useFallbackServer];
                }
            }
            else if (remainingTime <= 0)
            {
                NBLog(@"DNS update done.");

                self.dnsUpdateDate = [NSDate date];
                if (self.servers.count > 0)
                {
                    [self testServers];
                }
            }
            else
            {
                NBLog(@"DNS: This can't happen.");
            }
            
            DNSServiceRefDeallocate(sdRef);
        }
    }
}


- (void)useFallbackServer
{
    self.ttl = kFallbackServerTtl;

    NSMutableDictionary* server = [@{@"target"   : [Settings sharedSettings].fallbackServer,
                                     @"port"     : @(443),
                                     @"priority" : @(10),
                                     @"weight"   : @(10),
                                     @"ttl"      : @(kFallbackServerTtl)} mutableCopy];
    
    [self.servers addObject:server];
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

            NSMutableDictionary* server = [@{@"target"   : target,
                                             @"port"     : @(port),
                                             @"priority" : @(priority),
                                             @"weight"   : @(weight),
                                             @"ttl"      : @(ttl)} mutableCopy];

            [[WebInterface sharedInterface].servers addObject:server];
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
    [self.condition lock];

    NSArray* servers;
    
    @synchronized(self.servers)
    {
        servers = [self.servers copy];
        [self.servers removeAllObjects];
    }

    __block int failCount = 0;
    for (NSMutableDictionary* server in servers)
    {
        NSString* urlString = [NSString stringWithFormat:@"https://%@:%d%@",
                                                         server[@"target"],
                                                         [server[@"port"] intValue],
                                                         [Settings sharedSettings].serverTestUrlPath];

        NSDate* startDate = [NSDate date];
         NSURLSession *session = [NSURLSession sharedSession];
         [[session dataTaskWithURL:[NSURL URLWithString:urlString]
                 completionHandler:^(NSData* data, NSURLResponse* response, NSError* error)
        {
            // This code is NOT run on main thread!!!

            NSDictionary* reply = [Common objectWithJsonData:data];

// Got this error here at GENEVA airport (also did not select the fallback api.numberbay.com): Error Domain=NSURLErrorDomain Code=-1202 "The certificate for this server is invalid. You might be connecting to a server that is pretending to be “api3.numberbay.com” which could put your confidential information at risk." UserInfo=0x1703a3aa0 {NSURLErrorFailingURLPeerTrustErrorKey=<SecTrustRef: 0x1742c4910>, NSLocalizedRecoverySuggestion=Would you like to connect to the server anyway?, _kCFStreamErrorCodeKey=-9843

            if (reply != nil && [reply[@"status"] isEqualToString:@"OK"])
            {
                // This method returns as soon a the first response is received, meaning
                // that any other servers are added after `updateServers` is done.  For that
                // reason we need to mutally exclude access to `self.servers` here and in
                // `selectServer`.
                @synchronized(self.servers)
                {
                    if (reply[@"trace"] != nil)
                    {
                        [AnalyticsTransmitter sharedTransmitter].enabled = [reply[@"trace"] boolValue];
                    }
                    
                    server[@"delay"] = @([[NSDate date] timeIntervalSinceDate:startDate]);
                    [self.servers addObject:server];
                    
                    [self prepareServers];
                }
                
                [self.condition signal];
            }
            else
            {
                NBLog(@"Server test failed: %@", server[@"target"]);
                failCount++;
                [self.condition signal];
            }
        }] resume];
    }

    NSUInteger count;
    do
    {
        [self.condition wait];
        
        @synchronized(self.servers)
        {
            count = self.servers.count;
        }
    }
    while (count == 0 && failCount != servers.count);
    
    [self.condition unlock];
}


- (void)prepareServers
{
    // Sort servers in descending priority order.
    NSSortDescriptor* sortDescriptorPriority = [[NSSortDescriptor alloc] initWithKey:@"priority" ascending:YES];
    NSSortDescriptor* sortDescriptorDelay    = [[NSSortDescriptor alloc] initWithKey:@"delay"    ascending:YES];
    NSArray*          sortDescriptors        = @[sortDescriptorPriority, sortDescriptorDelay];
    
    @synchronized(self.servers)
    {
        [self.servers sortUsingDescriptors:sortDescriptors];
    }
    
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
    
    // See comment in `testServers` about mutual exclusive access to `self.servers`.
    @synchronized(self.servers)
    {
        NSDictionary* server;

        if (self.servers.count > 0)
        {
            if (self.selectedServer == nil ||
                [[NSDate date] timeIntervalSinceDate:self.selectedServerDate] > kSelectedServerHoldTime)
            {
                int priority = [self.servers[0][@"priority"] intValue];
                
                int weighter = 0;
                for (server in self.servers)
                {
                    if ([server[@"priority"] intValue] == priority)
                    {
                        weighter += [server[@"weight"] intValue];
                        
                        if ((self.weighter % self.weightSum) < weighter)
                        {
                            self.selectedServer = server;
                            break;
                        }
                    }

                    // Make sure there's always a server selected after the loop finishes.
                    self.selectedServer = server;
                }
                
                self.weighter += self.weighterIncrement;
            }
            else
            {
                server = self.selectedServer;
            }
            
            self.selectedServerDate = [NSDate date];
        }
        else
        {
            [self useFallbackServer];
            server = [self.servers firstObject];
        }
        
        NBLog(@"Selected server: %@.", server[@"target"]);
        
        return server;
    }
}


#pragma mark WebClient mapping methods

- (void)requestWithMethod:(RequestMethod)method
                     path:(NSString*)path
               parameters:(id)parameters
                 retrying:(BOOL)retrying
                  success:(void (^)(NSURLSessionTask* task, id responseObject))success
                  failure:(void (^)(NSURLSessionTask* task, NSError* error))failure
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^
    {
        NSDictionary* server = [self selectServer];
        if (server != nil)
        {
            [self.requestSerializer setAuthorizationHeaderFieldWithUsername:[Settings sharedSettings].webUsername
                                                                   password:[Settings sharedSettings].webPassword];
            
            NSString* urlString = [NSString stringWithFormat:@"https://%@:%d%@",
                                                             server[@"target"],
                                                             [server[@"port"] intValue],
                                                             path];

            void (^failureBlock)(NSURLSessionTask* task,
                                 NSError*          error) = ^void(NSURLSessionTask* task,
                                                                  NSError*          error)
            {
                if (error.code == NSURLErrorNotConnectedToInternet          ||
                    error.code == NSURLErrorCannotFindHost                  ||
                    error.code == NSURLErrorSecureConnectionFailed          ||
                    error.code == NSURLErrorServerCertificateHasBadDate     ||
                    error.code == NSURLErrorServerCertificateUntrusted      ||
                    error.code == NSURLErrorServerCertificateHasUnknownRoot ||
                    error.code == NSURLErrorServerCertificateNotYetValid    ||
                    error.code == NSURLErrorClientCertificateRejected       ||
                    error.code == NSURLErrorClientCertificateRequired       ||
                    error.code == NSURLErrorUserCancelledAuthentication     ||
                    error.code == NSURLErrorUserAuthenticationRequired)
                {
                    failure ? failure(task, error) : 0;
                }
                else if ([task.response isKindOfClass:[NSHTTPURLResponse class]] &&
                         ((NSHTTPURLResponse*)task.response).statusCode == 401) // Unauthorized.
                {
                    // Something is very wrong, do a hard logout of the user.
                    [[Settings sharedSettings] resetAll];
                    failure ? failure(task, error) : 0;
                }
                else if (error.code != NSURLErrorCancelled)
                {
                    if (retrying == NO)
                    {
                        // Retry once.
                        @synchronized(self.servers)
                        {
                            [self.servers removeAllObjects];
                            self.selectedServer = nil;
                        }
                    
                        NBLog(@"Retrying: %@", path);
                        [self requestWithMethod:method
                                           path:path
                                     parameters:parameters
                                       retrying:YES
                                        success:success
                                        failure:failure];
                    }
                    else
                    {
                        failure(task, error);
                    }
                }
            };

            switch (method)
            {
                case RequestMethodGet:
                {
                    [self GET:urlString parameters:parameters progress:nil success:success failure:failureBlock];

                    break;
                }
                case RequestMethodPost:
                {
                    [self POST:urlString parameters:parameters progress:nil success:success failure:failureBlock];

                    break;
                }
                case RequestMethodPut:
                {
                    [self PUT:urlString parameters:parameters success:success failure:failureBlock];

                    break;
                }
                case RequestMethodDelete:
                {
                    [self DELETE:urlString parameters:parameters success:success failure:failureBlock];

                    break;
                }
            }
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^
            {
                NSError* error = [Common errorWithCode:WebStatusFailNoServer
                                           description:[WebStatus localizedStringForStatus:WebStatusFailNoServer]];
                failure ? failure(nil, error) : 0;
            });
        }
    });
}


- (void)getPath:(NSString*)path
     parameters:(id)parameters
        success:(void (^)(NSURLSessionTask* task, id responseObject))success
        failure:(void (^)(NSURLSessionTask* task, NSError* error))failure
{
    [self requestWithMethod:RequestMethodGet path:path parameters:parameters retrying:NO success:success failure:failure];
}


- (void)postPath:(NSString*)path
      parameters:(id)parameters
         success:(void (^)(NSURLSessionTask* task, id responseObject))success
         failure:(void (^)(NSURLSessionTask* task, NSError* error))failure
{
    [self requestWithMethod:RequestMethodPost path:path parameters:parameters retrying:NO success:success failure:failure];
}


- (void)putPath:(NSString*)path
     parameters:(id)parameters
        success:(void (^)(NSURLSessionTask* task, id responseObject))success
        failure:(void (^)(NSURLSessionTask* task, NSError* error))failure
{
    [self requestWithMethod:RequestMethodPut path:path parameters:parameters retrying:NO success:success failure:failure];
}


- (void)deletePath:(NSString*)path
        parameters:(id)parameters
           success:(void (^)(NSURLSessionTask* task, id responseObject))success
           failure:(void (^)(NSURLSessionTask* task, NSError* error))failure
{
    [self requestWithMethod:RequestMethodDelete path:path parameters:parameters retrying:NO success:success failure:failure];
}


- (void)cancelAllHttpRequestsWithMethod:(RequestMethod)method path:(NSString*)path
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^
    {
        for (NSURLSessionTask* task in self.tasks)
        {
            NSString* methodString;
            switch (method)
            {
                case RequestMethodGet:    methodString = @"GET";    break;
                case RequestMethodPost:   methodString = @"POST";   break;
                case RequestMethodPut:    methodString = @"PUT";    break;
                case RequestMethodDelete: methodString = @"DELETE"; break;
            }

            if ([task.originalRequest.HTTPMethod isEqualToString:methodString] &&
                [task.originalRequest.URL.path   isEqualToString:path])
            {
                NBLog(@"Cancelling HTTP %@ %@", methodString, path);
                [task cancel];
            }
        }
    });
}


- (void)cancelAllHttpRequests
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^
    {
        for (NSURLSessionTask* task in self.tasks)
        {
            [task cancel];
        }
    });
}


#pragma mark - Helper Methods

- (void)handleSuccess:(NSDictionary*)responseDictionary reply:(void (^)(NSError* error, id content))reply
{
    WebStatusCode code;
    id            content = responseDictionary[@"content"];
    
    if (responseDictionary != nil && [responseDictionary isKindOfClass:[NSDictionary class]])
    {
        NSString* string = responseDictionary[@"status"];
        
        code = [WebStatus codeForString:string];
    }
    else
    {
        NBLog(@"WebStatusFailInvalidResponse content: %@", content);
        code = WebStatusFailInvalidResponse;
    }
    
    if (code == WebStatusOk)
    {
        reply(nil, content);
    }
    else
    {
        reply([Common errorWithCode:code description:[WebStatus localizedStringForStatus:code]], nil);
    }
}


- (void)handleFailure:(NSError*)error reply:(void (^)(NSError* error, id content))reply
{
    if (error != nil)
    {
        if (error.code == NSURLErrorCancelled)
        {
            // Ignore cancellation. We should never get here as `requestWithMethod` already ignores a cancellation.
        }
        else if (error.code == NSURLErrorNotConnectedToInternet)
        {
            reply([Common errorWithCode:WebStatusFailNoInternet
                            description:[WebStatus localizedStringForStatus:WebStatusFailNoInternet]], nil);
        }
        else if (error.code == NSURLErrorSecureConnectionFailed          ||
                 error.code == NSURLErrorServerCertificateHasBadDate     ||
                 error.code == NSURLErrorServerCertificateUntrusted      ||
                 error.code == NSURLErrorServerCertificateHasUnknownRoot ||
                 error.code == NSURLErrorServerCertificateNotYetValid    ||
                 error.code == NSURLErrorClientCertificateRejected       ||
                 error.code == NSURLErrorClientCertificateRequired)
        {
            reply([Common errorWithCode:WebStatusFailSecureInternet
                            description:[WebStatus localizedStringForStatus:WebStatusFailSecureInternet]], nil);
        }
        else if (error.code == NSURLErrorCannotFindHost)
        {
            reply([Common errorWithCode:WebStatusFailProblemInternet
                            description:[WebStatus localizedStringForStatus:WebStatusFailProblemInternet]], nil);
        }
        else if (error.code == NSURLErrorUserCancelledAuthentication     ||
                 error.code == NSURLErrorUserAuthenticationRequired)
        {
            reply([Common errorWithCode:WebStatusFailInternetLogin
                            description:[WebStatus localizedStringForStatus:WebStatusFailInternetLogin]], nil);
        }
        else if (error.code == NSURLErrorInternationalRoamingOff)
        {
            reply([Common errorWithCode:WebStatusFailRoamingOff
                            description:[WebStatus localizedStringForStatus:WebStatusFailRoamingOff]], nil);
        }
        else
        {
            reply([Common errorWithCode:WebStatusFailOther
                            description:[WebStatus localizedStringForStatus:WebStatusFailOther]], nil);
        }
    }
    else
    {
        NBLog(@"Unknown error: %@", error);
        
        // Very unlikely that AFNetworking fails without error being set.
        WebStatusCode code = WebStatusFailUnknown;
        reply([Common errorWithCode:code description:[WebStatus localizedStringForStatus:code]], nil);
    }
}


#pragma mark - Public Methods

- (void)postPath:(NSString*)path
      parameters:(NSDictionary*)parameters
           reply:(void (^)(NSError* error, id content))reply
{
    [self postPath:path
        parameters:parameters
           success:^(NSURLSessionTask* task, id responseObject)
    {
        NBLog(@"POST %@ : %@\n==> %@", path, parameters ? parameters : @"", responseObject);
        [self handleSuccess:responseObject reply:reply];
    }
           failure:^(NSURLSessionTask* task, NSError* error)
    {
        NBLog(@"POST %@ failure: %@", path, error);
        [self handleFailure:error reply:reply];
    }];
}


- (void)putPath:(NSString*)path
     parameters:(NSDictionary*)parameters
          reply:(void (^)(NSError* error, id content))reply
{
    [self putPath:path
       parameters:parameters
          success:^(NSURLSessionTask* task, id responseObject)
    {
        NBLog(@"PUT %@ : %@\n==> %@", path, parameters ? parameters : @"", responseObject);
        [self handleSuccess:responseObject reply:reply];
    }
          failure:^(NSURLSessionTask* task, NSError* error)
    {
        NBLog(@"PUT %@ failure: %@", path, error);
        [self handleFailure:error reply:reply];
    }];
}


- (void)getPath:(NSString*)path
     parameters:(NSDictionary*)parameters
          reply:(void (^)(NSError* error, id content))reply
{
    [self getPath:path
       parameters:parameters
          success:^(NSURLSessionTask* task, id responseObject)
    {
        NBLog(@"GET %@ : %@\n==> %@", path, parameters ? parameters : @"", responseObject);
        [self handleSuccess:responseObject reply:reply];
    }
          failure:^(NSURLSessionTask* task, NSError* error)
    {
        NBLog(@"GET %@ failure: %@", path, error);
        [self handleFailure:error reply:reply];
    }];
}


- (void)deletePath:(NSString*)path
        parameters:(NSDictionary*)parameters
             reply:(void (^)(NSError* error, id content))reply
{
    [self deletePath:path
          parameters:parameters
             success:^(NSURLSessionTask* task, id responseObject)
    {
        NBLog(@"DELETE %@ : %@\n==> %@", path, parameters ? parameters : @"", responseObject);
        [self handleSuccess:responseObject reply:reply];
    }
             failure:^(NSURLSessionTask* task, NSError* error)
    {
        NBLog(@"DELETE %@ failure: %@", path, error);
        [self handleFailure:error reply:reply];
    }];
}

@end
