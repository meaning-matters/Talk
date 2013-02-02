//
//  WebClient.m
//  Talk
//
//  Created by Cornelis van der Bent on 10/01/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "WebClient.h"
#import "AFJSONRequestOperation.h"
#import "Settings.h"
#import "Common.h"


static NSDictionary* statuses;


@implementation WebClient

static WebClient*   sharedClient;


#pragma mark - Singleton Stuff

+ (void)initialize
{
    if ([WebClient class] == self)
    {
        sharedClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:[Settings sharedSettings].webBaseUrl]];
        [sharedClient setParameterEncoding:AFJSONParameterEncoding];
        [sharedClient setDefaultHeader:@"Accept" value:@"application/json"];
        [sharedClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [sharedClient setAuthorizationHeaderWithUsername:[Settings sharedSettings].webUsername
                                                password:[Settings sharedSettings].webPassword];

        statuses = @{ @"OK":                          @(WebClientStatusOk),
                      @"FAIL_INVALID_REQUEST":        @(WebClientStatusFailInvalidRequest),
                      @"FAIL_SERVER_INTERNAL":        @(WebClientStatusFailServerIternal),
                      @"FAIL_SERVICE_UNAVAILABLE":    @(WebClientStatusFailServiceUnavailable),
                      @"FAIL_INVALID_RECEIPT":        @(WebClientStatusFailInvalidReceipt),
                      @"FAIL_DEVICE_NAME_NOT_UNIQUE": @(WebClientStatusFailDeviceNameNotUnique),
                      @"FAIL_NO_STATES_FOR_COUNTRY":  @(WebClientStatusFailNoStatesForCountry),
                      @"FAIL_INVALID_INFO":           @(WebClientStatusFailInvalidInfo),
                      @"FAIL_DATA_TOO_LARGE":         @(WebClientStatusFailDataTooLarge) };
    }
}


+ (id)allocWithZone:(NSZone*)zone
{
    if (sharedClient && [WebClient class] == self)
    {
        [NSException raise:NSGenericException format:@"Duplicate WebClient singleton creation"];
    }

    return [super allocWithZone:zone];
}


+ (WebClient*)sharedClient
{
    return sharedClient;
}


#pragma mark - Helper Methods

- (WebClientStatus)getResponseStatus:(NSDictionary*)response
{
    NSString*   string = [response objectForKey:@"status"];
    NSNumber*   number = [statuses objectForKey:string];

    if (number != nil)
    {
        return [number intValue];
    }
    else
    {
        return WebClientStatusFailUnspecified;
    }
}


#pragma mark - Public API

- (void)postAccounts:(NSDictionary*)parameters
               reply:(void (^)(WebClientStatus status, id content))reply
{
    assert(reply != nil);

    [Common enableNetworkActivityIndicator:YES];

    [self postPath:@"accounts"
        parameters:parameters
           success:^(AFHTTPRequestOperation* operation, id responseObject)
    {
        NSLog(@"getPath request: %@", operation.request.URL);
        [Common enableNetworkActivityIndicator:NO];

        NSDictionary* reponseDictionary = responseObject;
        if(responseObject && [reponseDictionary isKindOfClass:[NSDictionary class]])
        {
            reply([self getResponseStatus:reponseDictionary], [reponseDictionary objectForKey:@"content"]);
        }
        else
        {
            reply(WebClientStatusFailInvalidResponse, nil);
        }
    }
           failure:^(AFHTTPRequestOperation* operation, NSError* error)
    {
        [Common enableNetworkActivityIndicator:NO];
        reply(WebClientStatusFailNetworkProblem, nil); // Assumes server responds properly, or can be other problem.
    }];
}

@end
