//
//  WebClient.h
//  Talk
//
//  Created by Cornelis van der Bent on 10/01/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "AFHTTPClient.h"
#import "NumberType.h"


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

- (void)retrieveNumberStatesForIsoCountryCode:(NSString*)isoCountryCode
                                        reply:(void (^)(WebClientStatus status, id content))reply;

- (void)retrieveNumberAreasForIsoCountryCode:(NSString*)isoCountryCode
                                   stateCode:(NSString*)stateCode
                                       reply:(void (^)(WebClientStatus status, id content))reply;

- (void)retrieveNumberAreasForIsoCountryCode:(NSString*)isoCountryCode
                              numberTypeMask:(NumberTypeMask)numberTypeMask
                                       reply:(void (^)(WebClientStatus status, id content))reply;

- (void)retrieveNumberAreaInfoForIsoCountryCode:(NSString*)isoCountryCode
                                       areaCode:(NSString*)areaCode
                                          reply:(void (^)(WebClientStatus status, id content))reply;

- (void)cancelAllRetrieveWebAccount;

- (void)cancelAllRetrieveSipAccount;

- (void)cancelAllRetrieveCredit;

- (void)cancelAllRetrieveNumbers;

- (void)cancelAllRetrieveNumberCountries;

- (void)cancelAllRetrieveNumberStatesForCountryId:(NSString*)countryId;

- (void)cancelAllRetrieveNumberAreasForCountryId:(NSString*)countryId stateId:(NSString*)stateId;

- (void)cancelAllRetrieveNumberAreasForCountryId:(NSString*)countryId;

- (void)cancelAllRetrieveAreaInfoForIsoCountryCode:(NSString*)isoCountryCode areaCode:(NSString*)areaCode;

@end
