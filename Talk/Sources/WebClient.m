//
//  WebClient.m
//  Talk
//
//  Created by Cornelis van der Bent on 10/01/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//
//  See link below for all URL load error codes and give more details than WebClientStatusFailNetworkProblem:
//  https://developer.apple.com/library/mac/#documentation/Cocoa/Reference/Foundation/Miscellaneous/Foundation_Constants/Reference/reference.html


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
    NSString*   string = response[@"status"];
    NSNumber*   number = statuses[string];

    if (number != nil)
    {
        return [number intValue];
    }
    else
    {
        return WebClientStatusFailUnspecified;
    }
}


- (void)postPath:(NSString*)path
      parameters:(NSDictionary*)parameters
           reply:(void (^)(WebClientStatus status, id content))reply
{
    [Common enableNetworkActivityIndicator:YES];

    [sharedClient setAuthorizationHeaderWithUsername:[Settings sharedSettings].webUsername
                                            password:[Settings sharedSettings].webPassword];

    [self postPath:path
        parameters:parameters
           success:^(AFHTTPRequestOperation* operation, id responseObject)
    {
        [Common enableNetworkActivityIndicator:NO];

        NSDictionary* reponseDictionary = responseObject;
        if (responseObject && [reponseDictionary isKindOfClass:[NSDictionary class]])
        {
            reply([self getResponseStatus:reponseDictionary], reponseDictionary[@"content"]);
        }
        else
        {
            reply(WebClientStatusFailInvalidResponse, nil);
        }
    }
          failure:^(AFHTTPRequestOperation* operation, NSError* error)
    {
        [Common enableNetworkActivityIndicator:NO];
        if (error != nil && error.code != NSURLErrorCancelled)
        {
            reply(WebClientStatusFailNetworkProblem, nil); // Assumes server responds properly, or can be other problem.
        }
    }];
}


- (void)getPath:(NSString*)path
     parameters:(NSDictionary*)parameters
          reply:(void (^)(WebClientStatus status, id content))reply
{
    [Common enableNetworkActivityIndicator:YES];

    [sharedClient setAuthorizationHeaderWithUsername:[Settings sharedSettings].webUsername
                                            password:[Settings sharedSettings].webPassword];

    [self getPath:path
       parameters:parameters
          success:^(AFHTTPRequestOperation* operation, id responseObject)
    {
        [Common enableNetworkActivityIndicator:NO];

        NSDictionary* reponseDictionary = responseObject;
        if (responseObject && [reponseDictionary isKindOfClass:[NSDictionary class]])
        {
            reply([self getResponseStatus:reponseDictionary], reponseDictionary[@"content"]);
        }
        else
        {
            reply(WebClientStatusFailInvalidResponse, nil);
        }
    }
          failure:^(AFHTTPRequestOperation* operation, NSError* error)
    {
        [Common enableNetworkActivityIndicator:NO];
        if (error != nil && error.code != NSURLErrorCancelled)
        {
            reply(WebClientStatusFailNetworkProblem, nil); // Assumes server responds properly, or can be other problem.
        }
    }];
}


#pragma mark - Public API

#warning replace parameters with argument list and put as much logic of the API request in these methods!

- (void)retrieveWebAccount:(NSDictionary*)parameters
                     reply:(void (^)(WebClientStatus status, id content))reply
{
    [Common enableNetworkActivityIndicator:YES];

    [self postPath:@"users"
        parameters:parameters
           success:^(AFHTTPRequestOperation* operation, id responseObject)
    {
        NSLog(@"postPath request: %@", operation.request.URL);
        [Common enableNetworkActivityIndicator:NO];

        NSDictionary* reponseDictionary = responseObject;
        if (responseObject && [reponseDictionary isKindOfClass:[NSDictionary class]])
        {
            reply([self getResponseStatus:reponseDictionary], reponseDictionary[@"content"]);
        }
        else
        {
            reply(WebClientStatusFailInvalidResponse, nil);
        }
    }
           failure:^(AFHTTPRequestOperation* operation, NSError* error)
    {
        [Common enableNetworkActivityIndicator:NO];
        if (error != nil && error.code != NSURLErrorCancelled)
        {
            reply(WebClientStatusFailNetworkProblem, nil); // Assumes server responds properly, or can be other problem.
        }
    }];
}


- (void)retrieveSipAccount:(NSDictionary*)parameters
                    reply:(void (^)(WebClientStatus status, id content))reply
{
    [self postPath:[NSString stringWithFormat:@"users/%@/devices", [Settings sharedSettings].webUsername]
        parameters:parameters
             reply:reply];
}


- (void)retrieveCredit:(void (^)(WebClientStatus status, id content))reply
{
    [self getPath:[NSString stringWithFormat:@"users/%@/credit", [Settings sharedSettings].webUsername]
       parameters:nil
            reply:reply];
}


- (void)retrieveNumbers:(void (^)(WebClientStatus status, id content))reply
{
    [self getPath:[NSString stringWithFormat:@"users/%@/numbers", [Settings sharedSettings].webUsername]
       parameters:nil
            reply:reply];
}


- (void)retrieveNumberCountries:(void (^)(WebClientStatus status, id content))reply
{
    [self getPath:@"numbers/countries" parameters:nil reply:reply];
}


- (void)retrieveNumberStatesForIsoCountryCode:(NSString*)isoCountryCode
                                        reply:(void (^)(WebClientStatus status, id content))reply
{
    [self getPath:[NSString stringWithFormat:@"numbers/countries/%@/states", isoCountryCode]
       parameters:nil
            reply:reply];
}


- (void)retrieveNumberAreasForIsoCountryCode:(NSString*)isoCountryCode
                                   stateCode:(NSString*)stateCode
                                       reply:(void (^)(WebClientStatus status, id content))reply
{
    [self getPath:[NSString stringWithFormat:@"numbers/countries/%@/states/%@/areas", isoCountryCode, stateCode]
       parameters:nil
            reply:reply];
}


- (void)retrieveNumberAreasForIsoCountryCode:(NSString*)isoCountryCode
                              numberTypeMask:(NumberTypeMask)numberTypeMask
                                       reply:(void (^)(WebClientStatus status, id content))reply
{
    [self getPath:[NSString stringWithFormat:@"numbers/countries/%@/areas", isoCountryCode]
       parameters:@{ @"numberType" : [NumberType stringForNumberType:numberTypeMask] }
            reply:reply];
}


- (void)retrieveNumberAreaInfoForIsoCountryCode:(NSString*)isoCountryCode
                                       areaCode:(NSString*)areaCode
                                          reply:(void (^)(WebClientStatus status, id content))reply;
{
    [self getPath:[NSString stringWithFormat:@"numbers/countries/%@/areas/%@", isoCountryCode, areaCode]
       parameters:nil
            reply:reply];
}


#pragma mark - Public Utility

- (void)cancelAllRetrieveWebAccount
{
    [self cancelAllHTTPOperationsWithMethod:@"POST" path:@"users"];
}


- (void)cancelAllRetrieveSipAccount
{
    [self cancelAllHTTPOperationsWithMethod:@"POST"
                                       path:[NSString stringWithFormat:@"users/%@/devices",
                                             [Settings sharedSettings].webUsername]];
}


- (void)cancelAllRetrieveCredit
{
    [self cancelAllHTTPOperationsWithMethod:@"GET"
                                       path:[NSString stringWithFormat:@"users/%@/credit",
                                             [Settings sharedSettings].webUsername]];
}


- (void)cancelAllRetrieveNumbers
{
    [self cancelAllHTTPOperationsWithMethod:@"GET"
                                       path:[NSString stringWithFormat:@"users/%@/numbers",
                                             [Settings sharedSettings].webUsername]];
}


- (void)cancelAllRetrieveNumberCountries
{
    [self cancelAllHTTPOperationsWithMethod:@"GET"
                                       path:@"numbers/countries"];
}


- (void)cancelAllRetrieveNumberStatesForIsoCountryCode:(NSString*)isoCountryCode
{
    [self cancelAllHTTPOperationsWithMethod:@"GET"
                                       path:[NSString stringWithFormat:@"numbers/countries/%@/states",
                                             isoCountryCode]];
}


- (void)cancelAllRetrieveNumberAreasForIsoCountryCode:(NSString*)isoCountryCode stateCode:(NSString*)stateCode
{
    [self cancelAllHTTPOperationsWithMethod:@"GET"
                                       path:[NSString stringWithFormat:@"numbers/countries/%@/states/%@/areas",
                                             isoCountryCode, stateCode]];
}


- (void)cancelAllRetrieveNumberAreasForIsoCountryCode:(NSString*)isoCountryCode
{
    [self cancelAllHTTPOperationsWithMethod:@"GET"
                                       path:[NSString stringWithFormat:@"numbers/countries/%@/areas",
                                             isoCountryCode]];
}


- (void)cancelAllRetrieveAreaInfoForIsoCountryCode:(NSString*)isoCountryCode areaCode:(NSString*)areaCode
{
    [self cancelAllHTTPOperationsWithMethod:@"GET"
                                       path:[NSString stringWithFormat:@"numbers/countries/%@/areas/%@",
                                             isoCountryCode, areaCode]];
}

@end
