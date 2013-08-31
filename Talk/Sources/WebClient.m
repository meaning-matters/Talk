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
#import "PurchaseManager.h"


static NSDictionary* statuses;


@implementation WebClient

#pragma mark - Singleton Stuff

+ (WebClient*)sharedClient
{
    static WebClient*       sharedInstance;
    static dispatch_once_t  onceToken;

    dispatch_once(&onceToken, ^
    {
        sharedInstance = [[self alloc] initWithBaseURL:[NSURL URLWithString:[Settings sharedSettings].webBaseUrl]];

        [sharedInstance setParameterEncoding:AFJSONParameterEncoding];
        [sharedInstance setDefaultHeader:@"Accept" value:@"application/json"];
        [sharedInstance registerHTTPOperationClass:[AFJSONRequestOperation class]];

        statuses = @{ @"OK":                          @(WebClientStatusOk),
                      @"FAIL_INVALID_REQUEST":        @(WebClientStatusFailInvalidRequest),
                      @"FAIL_SERVER_INTERNAL":        @(WebClientStatusFailServerIternal),
                      @"FAIL_SERVICE_UNAVAILABLE":    @(WebClientStatusFailServiceUnavailable),
                      @"FAIL_INVALID_RECEIPT":        @(WebClientStatusFailInvalidReceipt),
                      @"FAIL_DEVICE_NAME_NOT_UNIQUE": @(WebClientStatusFailDeviceNameNotUnique),
                      @"FAIL_NO_STATES_FOR_COUNTRY":  @(WebClientStatusFailNoStatesForCountry),
                      @"FAIL_INVALID_INFO":           @(WebClientStatusFailInvalidInfo),
                      @"FAIL_DATA_TOO_LARGE":         @(WebClientStatusFailDataTooLarge),
                      @"FAIL_INSUFFICIENT_CREDIT":    @(WebClientStatusFailInsufficientCredit) };
    });

    return sharedInstance;
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

    [self setAuthorizationHeaderWithUsername:[Settings sharedSettings].webUsername
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


- (void)putPath:(NSString*)path
     parameters:(NSDictionary*)parameters
          reply:(void (^)(WebClientStatus status, id content))reply
{
    [Common enableNetworkActivityIndicator:YES];

    [self setAuthorizationHeaderWithUsername:[Settings sharedSettings].webUsername
                                    password:[Settings sharedSettings].webPassword];

    [self putPath:path
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

    [self setAuthorizationHeaderWithUsername:[Settings sharedSettings].webUsername
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

- (NSString*)localizedStringForStatus:(WebClientStatus)status
{
    NSString* string;

    switch (status)
    {
        case WebClientStatusOk:
            string = NSLocalizedStringWithDefaultValue(@"webClient StatusOk", nil, [NSBundle mainBundle],
                                                       @"Successful",
                                                       @"Status text.\n"
                                                       @"[].");
            break;

        case WebClientStatusFailInvalidRequest:
            string = NSLocalizedStringWithDefaultValue(@"webClient FailInvalidRequest", nil, [NSBundle mainBundle],
                                                       @"Couldn't communicate with the server",
                                                       @"Status text.\n"
                                                       @"[].");
            break;

        case WebClientStatusFailServerIternal:
            string = NSLocalizedStringWithDefaultValue(@"webClient FailServerIternal", nil, [NSBundle mainBundle],
                                                       @"Internal server issue",
                                                       @"Status text.\n"
                                                       @"[].");
            break;

        case WebClientStatusFailServiceUnavailable:
            string = NSLocalizedStringWithDefaultValue(@"webClient FailServiceUnavailable", nil, [NSBundle mainBundle],
                                                       @"Service is temporatily unavailable",
                                                       @"Status text.\n"
                                                       @"[].");
            break;

        case WebClientStatusFailInvalidReceipt:
            string = NSLocalizedStringWithDefaultValue(@"webClient FailInvalidReceipt", nil, [NSBundle mainBundle],
                                                       @"Electronic receipt is not valid",
                                                       @"Status text.\n"
                                                       @"[].");
            break;

        case WebClientStatusFailDeviceNameNotUnique:
            string = NSLocalizedStringWithDefaultValue(@"webClient FailDeviceNameNotUnique", nil, [NSBundle mainBundle],
                                                       @"All devices you register must have a unique name",
                                                       @"Status text.\n"
                                                       @"[].");
            break;

        case WebClientStatusFailNoStatesForCountry:
            string = NSLocalizedStringWithDefaultValue(@"webClient FailNoStatesForCountry", nil, [NSBundle mainBundle],
                                                       @"This country does not have states",
                                                       @"Status text.\n"
                                                       @"[].");
            break;

        case WebClientStatusFailInvalidInfo:
            string = NSLocalizedStringWithDefaultValue(@"webClient FailInvalidInfo", nil, [NSBundle mainBundle],
                                                       @"Your name and address were not accepted",
                                                       @"Status text.\n"
                                                       @"[].");
            break;

        case WebClientStatusFailDataTooLarge:
            string = NSLocalizedStringWithDefaultValue(@"webClient FailDataTooLarge", nil, [NSBundle mainBundle],
                                                       @"Too much data to load in one go",
                                                       @"Status text.\n"
                                                       @"[].");
            break;

        case WebClientStatusFailInsufficientCredit:
            string = NSLocalizedStringWithDefaultValue(@"webClient FailInsufficientCredit", nil, [NSBundle mainBundle],
                                                       @"You have not enough credit",
                                                       @"Status text.\n"
                                                       @"[].");
            break;

        case WebClientStatusFailNetworkProblem:
            string = NSLocalizedStringWithDefaultValue(@"webClient FailNetworkProblem", nil, [NSBundle mainBundle],
                                                       @"There's a problem with the network",
                                                       @"Status text.\n"
                                                       @"[].");
            break;

        case WebClientStatusFailInvalidResponse:
            string = NSLocalizedStringWithDefaultValue(@"webClient FailInvalidResponse", nil, [NSBundle mainBundle],
                                                       @"Invalid data received from server",
                                                       @"Status text.\n"
                                                       @"[].");
            break;

        case WebClientStatusFailUnspecified:
            string = NSLocalizedStringWithDefaultValue(@"webClient FailUnspecified", nil, [NSBundle mainBundle],
                                                       @"An unspecified issue",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
    }

    return string;
}


#warning replace parameters with argument list and put as much logic of the API request in these methods!

// 1. CREATE/UPDATE ACCOUNT
- (void)retrieveWebAccount:(NSDictionary*)parameters
                     reply:(void (^)(WebClientStatus status, id content))reply
{
    [Common enableNetworkActivityIndicator:YES];

    NSString* currencyCode = [Settings sharedSettings].currencyCode;
    [self postPath:[NSString stringWithFormat:@"users?currencyCode=%@", currencyCode]
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


// 2. ADD/UPDATE DEVICE
- (void)retrieveSipAccount:(NSDictionary*)parameters
                    reply:(void (^)(WebClientStatus status, id content))reply
{
    [self postPath:[NSString stringWithFormat:@"users/%@/devices", [Settings sharedSettings].webUsername]
        parameters:parameters
             reply:reply];
}


// 3. GET LIST OF DEVICES
// ...


// 4. GET DEVICE INFO
// ...


// 5. DELETE DEVICE
// ...


// 6. GET LIST OF ALL AVAILABLE NUMBER COUNTRIES
- (void)retrieveNumberCountries:(void (^)(WebClientStatus status, id content))reply
{
    [self getPath:@"numbers/countries" parameters:nil reply:reply];
}


// 7. GET LIST OF ALL AVAILABLE NUMBER STATES
- (void)retrieveNumberStatesForIsoCountryCode:(NSString*)isoCountryCode
                                        reply:(void (^)(WebClientStatus status, id content))reply
{
    [self getPath:[NSString stringWithFormat:@"numbers/countries/%@/states", isoCountryCode]
       parameters:nil
            reply:reply];
}


// 8A. GET LIST OF ALL AVAILABLE NUMBER AREAS (with states)
- (void)retrieveNumberAreasForIsoCountryCode:(NSString*)isoCountryCode
                                   stateCode:(NSString*)stateCode
                              numberTypeMask:(NumberTypeMask)numberTypeMask
                                currencyCode:(NSString*)currencyCode
                                       reply:(void (^)(WebClientStatus status, id content))reply
{
    [self getPath:[NSString stringWithFormat:@"numbers/countries/%@/states/%@/areas", isoCountryCode, stateCode]
       parameters:@{ @"numberType"   : [NumberType stringForNumberType:numberTypeMask],
                     @"currencyCode" : currencyCode }
            reply:reply];
}


// 8B. GET LIST OF ALL AVAILABLE NUMBER AREAS (no states)
- (void)retrieveNumberAreasForIsoCountryCode:(NSString*)isoCountryCode
                              numberTypeMask:(NumberTypeMask)numberTypeMask
                                currencyCode:(NSString*)currencyCode
                                       reply:(void (^)(WebClientStatus status, id content))reply
{
    [self getPath:[NSString stringWithFormat:@"numbers/countries/%@/areas", isoCountryCode]
       parameters:@{ @"numberType"   : [NumberType stringForNumberType:numberTypeMask],
                     @"currencyCode" : currencyCode }
            reply:reply];
}


// 9. GET PURCHASE INFO DATA
- (void)retrieveNumberAreaInfoForIsoCountryCode:(NSString*)isoCountryCode
                                       areaCode:(NSString*)areaCode
                                          reply:(void (^)(WebClientStatus status, id content))reply;
{
    [self getPath:[NSString stringWithFormat:@"numbers/countries/%@/areas/%@", isoCountryCode, areaCode]
       parameters:nil
            reply:reply];
}


// 10. CHECK IF PURCHASE INFO IS VALID
- (void)checkPurchaseInfo:(NSDictionary*)parameters
                    reply:(void (^)(WebClientStatus status, id content))reply
{
    [self postPath:@"numbers/check" parameters:parameters reply:reply];
}


// 11A. PURCHASE NUMBER
- (void)purchaseNumberForReceipt:(NSString*)receipt
                          months:(int)months
                            name:(NSString*)name
                  isoCountryCode:(NSString*)isoCountryCode
                        areaCode:(NSString*)areaCode
                      numberType:(NSString*)numberType
                            info:(NSDictionary*)info
                           reply:(void (^)(WebClientStatus status, NSString* e164))reply
{
    NSString* username              = [Settings sharedSettings].webUsername;
    NSMutableDictionary* parameters = [@{@"receipt"        : receipt,
                                         @"durationMonths" : @(months),
                                         @"name"           : name,
                                         @"isoCountryCode" : isoCountryCode,
                                         @"areaCode"       : areaCode,
                                         @"numberType"     : numberType} mutableCopy];
    if (info != nil)
    {
        [parameters setObject:info forKey:@"info"];
    }

    [parameters setObject:@(true) forKey:@"debug"];

    [self postPath:[NSString stringWithFormat:@"users/%@/numbers", username]
        parameters:parameters
             reply:^(WebClientStatus status, id content)
     {
         if (status == WebClientStatusOk)
         {
             reply(status, content[@"e164"]);
         }
         else
         {
             reply(status, nil);
         }
     }];
}


// 11B. UPDATE NUMBER'S NAME
// ...


// 11C.



// 12. GET LIST OF NUMBERS
- (void)retrieveNumbers:(void (^)(WebClientStatus status, id content))reply
{
    [self getPath:[NSString stringWithFormat:@"users/%@/numbers", [Settings sharedSettings].webUsername]
       parameters:nil
            reply:reply];
}


// 13. GET NUMBER INFO
// ...


// 14. BUY CREDIT
- (void)purchaseCreditForReceipt:(NSString*)receipt currencyCode:(NSString*)currencyCode
                           reply:(void (^)(WebClientStatus status, float credit))reply
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self postPath:[NSString stringWithFormat:@"users/%@/credit?currencyCode=%@", username, currencyCode]
        parameters:@{@"receipt" : receipt}
             reply:^(WebClientStatus status, id content)
    {
        if (status == WebClientStatusOk)
        {
            reply(status, [content[@"credit"] floatValue]);
        }
        else
        {
            reply(status, 0.0f);
        }
    }];
}


// 15. GET CURRENT CALLING CREDIT
- (void)retrieveCreditForCurrencyCode:(NSString*)currencyCode
                                reply:(void (^)(WebClientStatus status, id content))reply
{
    [self getPath:[NSString stringWithFormat:@"users/%@/credit", [Settings sharedSettings].webUsername]
       parameters:@{@"currencyCode" : currencyCode}
            reply:reply];
}


// 16. GET CALL RATE (PER MINUTE)
// ...


// 17. GET CDRS
// ...


// 18. GET VOICEMAIL STATUS
// ...


// 19. UPLOAD IVR OR UPDATE IVR
// ...

// 20. DELETE IVR
// ...


// 21. GET LIST IVR UUID'S ON SERVER
// ...


// 22. DOWNLOAD IVR
// ...


// 23. SET/CLEAR IVR FOR A NUMBER
// ...


// 24. RETRIEVE IVR FOR A NUMBER
// ...


// 25. UPLOAD AUDIO OR RENAME AUDIO FILE
// ...


// 26. DOWNLOAD AUDIO FILE
// ...


// 27. DELETE AUDIO FILE
// ...


// 28. GET LIST OF AUDIO UUID'S ON SERVER
// ...


// 29. USER FEEDBACK
// ...


// 30A.
- (void)retrieveVerificationCodeForPhoneNumber:(PhoneNumber*)phoneNumber
                                        reply:(void (^)(WebClientStatus status, NSString* code))reply
{
    [self postPath:[NSString stringWithFormat:@"users/%@/verification?number=%@",
                    [Settings sharedSettings].webUsername, [phoneNumber e164FormatWithoutPlus]]
        parameters:nil
             reply:^(WebClientStatus status, id content)
    {
        if (status == WebClientStatusOk)
        {
            reply(status, content[@"code"]);
        }
        else
        {
            reply(status, nil);
        }
    }];
}


// 30B.
- (void)requestVerificationCallForPhoneNumber:(PhoneNumber*)phoneNumber
                                        reply:(void (^)(WebClientStatus status))reply
{
    [self putPath:[NSString stringWithFormat:@"users/%@/verification?number=%@",
                    [Settings sharedSettings].webUsername, [phoneNumber e164FormatWithoutPlus]]
        parameters:nil
             reply:^(WebClientStatus status, id content)
     {
         if (status == WebClientStatusOk)
         {
             reply(status);
         }
         else
         {
             reply(status);
         }
     }];
}


// 30C.
- (void)retrieveVerificationStatusForPhoneNumber:(PhoneNumber*)phoneNumber
                                           reply:(void (^)(WebClientStatus status, BOOL calling, BOOL verified))reply
{
    [self getPath:[NSString stringWithFormat:@"users/%@/verification", [Settings sharedSettings].webUsername]
       parameters:@{@"number" : [phoneNumber e164FormatWithoutPlus]}
            reply:^(WebClientStatus status, id content)
     {
         if (status == WebClientStatusOk)
         {
             reply(status, [content[@"calling"] boolValue], [content[@"verified"] boolValue]);
         }
         else
         {
             reply(status, NO, NO);
         }
     }];
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


- (void)cancelAllCheckPurchaseInfo
{
    [self cancelAllHTTPOperationsWithMethod:@"POST" path:@"numbers/check"];
}


- (void)cancelAllPurchaseNumber
{
    [self cancelAllHTTPOperationsWithMethod:@"POST"
                                       path:[NSString stringWithFormat:@"users/%@/numbers",
                                             [Settings sharedSettings].webUsername]];
}


- (void)cancelAllRetrieveNumbers
{
    [self cancelAllHTTPOperationsWithMethod:@"GET"
                                       path:[NSString stringWithFormat:@"users/%@/numbers",
                                             [Settings sharedSettings].webUsername]];
}


- (void)cancelAllRetrieveCredit
{
    [self cancelAllHTTPOperationsWithMethod:@"GET"
                                       path:[NSString stringWithFormat:@"users/%@/credit",
                                             [Settings sharedSettings].webUsername]];
}


- (void)cancelAllRetrieveVerificationCode
{
    [self cancelAllHTTPOperationsWithMethod:@"POST"
                                       path:[NSString stringWithFormat:@"users/%@/verification",
                                             [Settings sharedSettings].webUsername]];
}


- (void)cancelAllRequestVerificationCall
{
    [self cancelAllHTTPOperationsWithMethod:@"PUT"
                                       path:[NSString stringWithFormat:@"users/%@/verification",
                                             [Settings sharedSettings].webUsername]];
}


- (void)cancelAllRetrieveVerificationStatus
{
    [self cancelAllHTTPOperationsWithMethod:@"GET"
                                       path:[NSString stringWithFormat:@"users/%@/verification",
                                             [Settings sharedSettings].webUsername]];
}

@end
