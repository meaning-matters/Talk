//
//  WebClient.h
//  Talk
//
//  Created by Cornelis van der Bent on 10/01/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//
//  List of errors: https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Miscellaneous/Foundation_Constants/Reference/reference.html#//apple_ref/doc/uid/TP40003793-CH3g-SW40

#import "AFHTTPClient.h"
#import "NumberType.h"
#import "PhoneNumber.h"
#import "Call.h"


typedef enum
{
    WebClientStatusOk,
    WebClientStatusFailInvalidRequest        = 911001,
    WebClientStatusFailServerIternal         = 911002,
    WebClientStatusFailServiceUnavailable    = 911003,
    WebClientStatusFailInvalidReceipt        = 911004,
    WebClientStatusFailDeviceNameNotUnique   = 911005,
    WebClientStatusFailNoStatesForCountry    = 911006,
    WebClientStatusFailInvalidInfo           = 911007,
    WebClientStatusFailDataTooLarge          = 911008,
    WebClientStatusFailInsufficientCredit    = 911009,
    WebClientStatusFailIvrInUse              = 911010,
    WebClientStatusFailCallbackAlreadyActive = 911011,
    WebClientStatusFailNoCallbackFound       = 911012,
    WebClientStatusFailNoAccount             = 911051, // Indirect: not sent by server.
    WebClientStatusFailUnspecified           = 911052, // Indirect: not sent by server.
    WebClientStatusFailInvalidResponse       = 911053, // Indirect: not sent by server.
    WebClientStatusFailUnknown               = 911054, // Extreme unlikely situation where AFNetworking gives failure with error == nil.
} WebClientStatus;


@interface WebClient : AFHTTPClient

+ (WebClient*)sharedClient;


#pragma mark - Request Methods

// 1. CREATE/UPDATE ACCOUNT
- (void)retrieveWebAccount:(NSDictionary*)parameters
                     reply:(void (^)(NSError* error, id content))reply;

// 2. ADD/UPDATE DEVICE
- (void)retrieveSipAccount:(NSDictionary*)parameters
                     reply:(void (^)(NSError* error, id content))reply;

// 6. GET LIST OF ALL AVAILABLE NUMBER COUNTRIES
- (void)retrieveNumberCountries:(void (^)(NSError* error, id content))reply;

// 7. GET LIST OF ALL AVAILABLE NUMBER STATES
- (void)retrieveNumberStatesForIsoCountryCode:(NSString*)isoCountryCode
                                        reply:(void (^)(NSError* error, id content))reply;

// 8A. GET LIST OF ALL AVAILABLE NUMBER AREAS (WITH STATES)
- (void)retrieveNumberAreasForIsoCountryCode:(NSString*)isoCountryCode
                                   stateCode:(NSString*)stateCode
                              numberTypeMask:(NumberTypeMask)numberTypeMask
                                currencyCode:(NSString*)currencyCode
                                       reply:(void (^)(NSError* error, id content))reply;

// 8B. GET LIST OF ALL AVAILABLE NUMBER AREAS
- (void)retrieveNumberAreasForIsoCountryCode:(NSString*)isoCountryCode
                              numberTypeMask:(NumberTypeMask)numberTypeMask
                                currencyCode:(NSString*)currencyCode
                                       reply:(void (^)(NSError* error, id content))reply;

//  9. GET PURCHASE INFO DATA
- (void)retrieveNumberAreaInfoForIsoCountryCode:(NSString*)isoCountryCode
                                       areaCode:(NSString*)areaCode
                                          reply:(void (^)(NSError* error, id content))reply;

// 10. CHECK IF PURCHASE INFO IS VALID
- (void)checkPurchaseInfo:(NSDictionary*)parameters
                    reply:(void (^)(NSError* error, id content))reply;

// 11A. PURCHASE NUMBER
- (void)purchaseNumberForReceipt:(NSString*)receipt
                          months:(int)months
                            name:(NSString*)name
                  isoCountryCode:(NSString*)isoCountryCode
                        areaCode:(NSString*)areaCode
                        areaName:(NSString*)areaName
                       stateCode:(NSString*)stateCode
                       stateName:(NSString*)stateName
                      numberType:(NSString*)numberType
                            info:(NSDictionary*)info
                           reply:(void (^)(NSError* error, NSString* e164))reply;

// 11B.
- (void)updateNumberForE164:(NSString*)e164 withName:(NSString*)name reply:(void (^)(NSError* error))reply;

// 12. GET LIST OF NUMBERS
- (void)retrieveNumberList:(void (^)(NSError* error, NSArray* list))reply;

// 13. GET NUMBER INFO
- (void)retrieveNumberForE164:(NSString*)e164
                 currencyCode:(NSString*)currencyCode
                        reply:(void (^)(NSError* error, NSDictionary* dictionary))reply;

// 14. BUY CREDIT
- (void)purchaseCreditForReceipt:(NSString*)receipt
                    currencyCode:(NSString*)currencyCode
                           reply:(void (^)(NSError* error, float credit))reply;

// 15. GET CURRENT CREDIT
- (void)retrieveCreditForCurrencyCode:(NSString*)currencyCode
                                reply:(void (^)(NSError* error, id content))reply;

// 19A. CREATE IVR
- (void)createIvrForUuid:(NSString*)uuid
                    name:(NSString*)name
              statements:(NSArray*)statements
                   reply:(void (^)(NSError* error))reply;

// 19B. UPDATE IVR
- (void)updateIvrForUuid:(NSString*)uuid
                    name:(NSString*)name
              statements:(NSArray*)statements
                   reply:(void (^)(NSError* error))reply;

// 20. DELETE IVR
- (void)deleteIvrForUuid:(NSString*)uuid
                   reply:(void (^)(NSError* error))reply;

// 21. GET LIST OF IVRS
- (void)retrieveIvrList:(void (^)(NSError* error, NSArray* list))reply;

// 22. DOWNLOAD IVR
- (void)retrieveIvrForUuid:(NSString*)uuid
                     reply:(void (^)(NSError* error, NSString* name, NSArray* statements))reply;

// 23. SET/CLEAR IVR FOR A NUMBER
- (void)setIvrOfE164:(NSString*)e164
                uuid:(NSString*)uuid
               reply:(void (^)(NSError* error))reply;

// 24. RETRIEVE IVR FOR A NUMBER
- (void)retrieveIvrOfE164:(NSString*)e164
                    reply:(void (^)(NSError* error, NSString* uuid))reply;


// 30A. DO NUMBER VERIFICATION
- (void)retrieveVerificationCodeForPhoneNumber:(PhoneNumber*)phoneNumber
                                    deviceName:(NSString*)deviceName
                                         reply:(void (^)(NSError* error, NSString* code))reply;

// 30B. DO NUMBER VERIFICATION
- (void)requestVerificationCallForPhoneNumber:(PhoneNumber*)phoneNumber
                                        reply:(void (^)(NSError* error))reply;

// 30C. DO NUMBER VERIFICATION
- (void)retrieveVerificationStatusForPhoneNumber:(PhoneNumber*)phoneNumber
                                           reply:(void (^)(NSError* error, BOOL calling, BOOL verified))reply;

// 32. INITIATE CALLBACK
- (void)initiateCallbackForCallee:(PhoneNumber*)calleePhoneNumber
                           caller:(PhoneNumber*)callerPhoneNumber
                         identity:(PhoneNumber*)identityPhoneNumber
                          privacy:(BOOL)privacy
                            reply:(void (^)(NSError* error, NSString* uuid))reply;

// 33. STOP CALLBACK
- (void)stopCallbackForUuid:(NSString*)uuid
                      reply:(void (^)(NSError* error))reply;

// 34. GET CALLBACK STATE
- (void)retrieveCallbackStateForUuid:(NSString*)uuid
                               reply:(void (^)(NSError* error, CallState state))reply;

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

// 11B.
- (void)cancelAllUpdateNumberForE164:(NSString*)e164;

// 12.
- (void)cancelAllRetrieveNumberList;

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

// 32.
- (void)cancelAllInitiateCallback;

// 33.
- (void)cancelAllStopCallbackForUuid:(NSString*)uuid;

// 34.
- (void)cancelAllRetrieveCallbackStateForUuid:(NSString*)uuid;

@end
