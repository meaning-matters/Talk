//
//  WebClient.h
//  Talk
//
//  Created by Cornelis van der Bent on 10/01/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "AFHTTPClient.h"


typedef enum
{
    WebClientStatusOk,
    WebClientStatusFailInvalidRequest,
    WebClientStatusFailServerIternal,
    WebClientStatusFailServiceUnavailable,
    WebClientStatusFailInvalidReceipt,
    WebClientStatusFailDeviceNameNotUnique,
    WebClientStatusFailNoStatesForCountry,
    WebClientStatusFailInvalidInfo,
    WebClientStatusFailDataTooLarge,
    WebClientStatusFailNetworkProblem,  // Local.
    WebClientStatusFailInvalidResponse, // Local.
    WebClientStatusFailUnspecified,     // Local.
} WebClientStatus;


@interface WebClient : AFHTTPClient

+ (WebClient*)sharedClient;

- (void)retrieveWebAccount:(NSDictionary*)parameters
                     reply:(void (^)(WebClientStatus status, id content))reply;

- (void)retrieveSipAccount:(NSDictionary*)parameters
                     reply:(void (^)(WebClientStatus status, id content))reply;

- (void)retrieveCredit:(void (^)(WebClientStatus status, id content))reply;

- (void)retrieveNumbers:(void (^)(WebClientStatus status, id content))reply;

- (void)retrieveNumberCountries:(void (^)(WebClientStatus status, id content))reply;


- (void)cancelAllRetrieveWebAccount;

- (void)cancelAllRetrieveSipAccount;

- (void)cancelAllRetrieveCredit;

- (void)cancelAllRetrieveNumbers;

- (void)cancelAllRetrieveNumberCountries;

@end
