//
//  WebClient.h
//  Talk
//
//  Created by Cornelis van der Bent on 10/01/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "AFHTTPClient.h"
#import "NumberType.h"
#import "PhoneNumber.h"


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

- (void)retrieveNumberCountries:(void (^)(WebClientStatus status, id content))reply;

- (void)retrieveNumberStatesForIsoCountryCode:(NSString*)isoCountryCode
                                        reply:(void (^)(WebClientStatus status, id content))reply;

- (void)retrieveNumberAreasForIsoCountryCode:(NSString*)isoCountryCode
                                   stateCode:(NSString*)stateCode
                              numberTypeMask:(NumberTypeMask)numberTypeMask
                                currencyCode:(NSString*)currencyCode
                                       reply:(void (^)(WebClientStatus status, id content))reply;

- (void)retrieveNumberAreasForIsoCountryCode:(NSString*)isoCountryCode
                              numberTypeMask:(NumberTypeMask)numberTypeMask
                                currencyCode:(NSString*)currencyCode
                                       reply:(void (^)(WebClientStatus status, id content))reply;

- (void)retrieveNumberAreaInfoForIsoCountryCode:(NSString*)isoCountryCode
                                       areaCode:(NSString*)areaCode
                                          reply:(void (^)(WebClientStatus status, id content))reply;

- (void)checkPurchaseInfo:(NSDictionary*)parameters
                    reply:(void (^)(WebClientStatus status, id content))reply;

- (void)purchaseNumberForReceipt:(NSString*)receipt
                            name:(NSString*)name
                  isoCountryCode:(NSString*)isoCountryCode
                        areaCode:(int)areaCode
                      numberType:(NumberTypeMask)numberTypeMask
                            info:(NSDictionary*)info
                           reply:(void (^)(WebClientStatus status, NSString* e164))reply;

- (void)retrieveNumbers:(void (^)(WebClientStatus status, id content))reply;

- (void)purchaseCreditForReceipt:(NSString*)receipt
                    currencyCode:(NSString*)currencyCode
                           reply:(void (^)(WebClientStatus status, float credit))reply;

- (void)retrieveCredit:(void (^)(WebClientStatus status, id content))reply;

- (void)retrieveVerificationCodeForPhoneNumber:(PhoneNumber*)phoneNumber
                                         reply:(void (^)(WebClientStatus status, NSString* code))reply;

- (void)requestVerificationCallForPhoneNumber:(PhoneNumber*)phoneNumber
                                        reply:(void (^)(WebClientStatus status))reply;

- (void)retrieveVerificationStatusForPhoneNumber:(PhoneNumber*)phoneNumber
                                           reply:(void (^)(WebClientStatus status, BOOL calling, BOOL verified))reply;


- (void)cancelAllRetrieveWebAccount;

- (void)cancelAllRetrieveSipAccount;

- (void)cancelAllRetrieveNumberCountries;

- (void)cancelAllRetrieveNumberStatesForIsoCountryCode:(NSString*)isoCountryCode;

- (void)cancelAllRetrieveNumberAreasForIsoCountryCode:(NSString*)isoCountryCode stateCode:(NSString*)stateCode;

- (void)cancelAllRetrieveNumberAreasForIsoCountryCode:(NSString*)isoCountryCode;

- (void)cancelAllRetrieveAreaInfoForIsoCountryCode:(NSString*)isoCountryCode areaCode:(NSString*)areaCode;

- (void)cancelAllCheckPurchaseInfo;

- (void)cancelAllPurchaseNumber;

- (void)cancelAllRetrieveNumbers;

- (void)cancelAllPurchaseCredit;

- (void)cancelAllRetrieveCredit;

- (void)cancelAllRetrieveVerificationCode;

- (void)cancelAllRequestVerificationCall;

- (void)cancelAllRetrieveVerificationStatus;

@end
