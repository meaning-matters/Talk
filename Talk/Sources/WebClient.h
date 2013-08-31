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
    WebClientStatusFailInsufficientCredit,
    WebClientStatusFailNetworkProblem,  // Local.
    WebClientStatusFailInvalidResponse, // Local.
    WebClientStatusFailUnspecified,     // Local.
} WebClientStatus;


@interface WebClient : AFHTTPClient

+ (WebClient*)sharedClient;

- (NSString*)localizedStringForStatus:(WebClientStatus)status;


#pragma mark - Request Methods

// 1. CREATE/UPDATE ACCOUNT
- (void)retrieveWebAccount:(NSDictionary*)parameters
                     reply:(void (^)(WebClientStatus status, id content))reply;

// 2. ADD/UPDATE DEVICE
- (void)retrieveSipAccount:(NSDictionary*)parameters
                     reply:(void (^)(WebClientStatus status, id content))reply;

// 6. GET LIST OF ALL AVAILABLE NUMBER COUNTRIES
- (void)retrieveNumberCountries:(void (^)(WebClientStatus status, id content))reply;

// 7. GET LIST OF ALL AVAILABLE NUMBER STATES
- (void)retrieveNumberStatesForIsoCountryCode:(NSString*)isoCountryCode
                                        reply:(void (^)(WebClientStatus status, id content))reply;

// 8A. GET LIST OF ALL AVAILABLE NUMBER AREAS (WITH STATES)
- (void)retrieveNumberAreasForIsoCountryCode:(NSString*)isoCountryCode
                                   stateCode:(NSString*)stateCode
                              numberTypeMask:(NumberTypeMask)numberTypeMask
                                currencyCode:(NSString*)currencyCode
                                       reply:(void (^)(WebClientStatus status, id content))reply;

// 8B. GET LIST OF ALL AVAILABLE NUMBER AREAS
- (void)retrieveNumberAreasForIsoCountryCode:(NSString*)isoCountryCode
                              numberTypeMask:(NumberTypeMask)numberTypeMask
                                currencyCode:(NSString*)currencyCode
                                       reply:(void (^)(WebClientStatus status, id content))reply;

//  9. GET PURCHASE INFO DATA
- (void)retrieveNumberAreaInfoForIsoCountryCode:(NSString*)isoCountryCode
                                       areaCode:(NSString*)areaCode
                                          reply:(void (^)(WebClientStatus status, id content))reply;

// 10. CHECK IF PURCHASE INFO IS VALID
- (void)checkPurchaseInfo:(NSDictionary*)parameters
                    reply:(void (^)(WebClientStatus status, id content))reply;

// 11A. PURCHASE NUMBER
- (void)purchaseNumberForReceipt:(NSString*)receipt
                          months:(int)months
                            name:(NSString*)name
                  isoCountryCode:(NSString*)isoCountryCode
                        areaCode:(NSString*)areaCode
                      numberType:(NSString*)numberType
                            info:(NSDictionary*)info
                           reply:(void (^)(WebClientStatus status, NSString* e164))reply;

// 12. GET LIST OF NUMBERS
- (void)retrieveNumbers:(void (^)(WebClientStatus status, NSArray* array))reply;

// 13. GET NUMBER INFO
- (void)retrieveNumberForE164:(NSString*)e164
                 currencyCode:(NSString*)currencyCode
                        reply:(void (^)(WebClientStatus status, NSDictionary* dictionary))reply;

// 14. BUY CREDIT
- (void)purchaseCreditForReceipt:(NSString*)receipt
                    currencyCode:(NSString*)currencyCode
                           reply:(void (^)(WebClientStatus status, float credit))reply;

// 15. GET CURRENT CREDIT
- (void)retrieveCreditForCurrencyCode:(NSString*)currencyCode
                                reply:(void (^)(WebClientStatus status, id content))reply;

// 30A. DO NUMBER VERIFICATION
- (void)retrieveVerificationCodeForPhoneNumber:(PhoneNumber*)phoneNumber
                                         reply:(void (^)(WebClientStatus status, NSString* code))reply;

// 30B. DO NUMBER VERIFICATION
- (void)requestVerificationCallForPhoneNumber:(PhoneNumber*)phoneNumber
                                        reply:(void (^)(WebClientStatus status))reply;

// 30C. DO NUMBER VERIFICATION
- (void)retrieveVerificationStatusForPhoneNumber:(PhoneNumber*)phoneNumber
                                           reply:(void (^)(WebClientStatus status, BOOL calling, BOOL verified))reply;


#pragma mark - Cancel Methods

// 1.
- (void)cancelAllRetrieveWebAccount;

// 2.
- (void)cancelAllRetrieveSipAccount;

// 6.
- (void)cancelAllRetrieveNumberCountries;

// 7.
- (void)cancelAllRetrieveNumberStatesForIsoCountryCode:(NSString*)isoCountryCode;

// 8A.
- (void)cancelAllRetrieveNumberAreasForIsoCountryCode:(NSString*)isoCountryCode stateCode:(NSString*)stateCode;

// 8B.
- (void)cancelAllRetrieveNumberAreasForIsoCountryCode:(NSString*)isoCountryCode;

// 9.
- (void)cancelAllRetrieveAreaInfoForIsoCountryCode:(NSString*)isoCountryCode areaCode:(NSString*)areaCode;

// 10.
- (void)cancelAllCheckPurchaseInfo;

// 11A.
- (void)cancelAllPurchaseNumber;

// 12.
- (void)cancelAllRetrieveNumbers;

// 13.
- (void)cancelAllRetrieveNumberForE164:(NSString*)e164;

// 14.
- (void)cancelAllPurchaseCredit;

// 15.
- (void)cancelAllRetrieveCredit;

// 30A.
- (void)cancelAllRetrieveVerificationCode;

// 30B.
- (void)cancelAllRequestVerificationCall;

// 30C.
- (void)cancelAllRetrieveVerificationStatus;

@end
