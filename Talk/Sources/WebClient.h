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
#import "Call.h"


typedef enum
{
    WebClientStatusOk,
    WebClientStatusFailInvalidRequest        = 911001,
    WebClientStatusFailServerIternal         = 911002,
    WebClientStatusFailServiceUnavailable    = 911003,
    WebClientStatusFailInvalidReceipt        = 911004,
    WebClientStatusFailNoStatesForCountry    = 911005,
    WebClientStatusFailInvalidInfo           = 911006,
    WebClientStatusFailDataTooLarge          = 911007,
    WebClientStatusFailInsufficientCredit    = 911008,
    WebClientStatusFailIvrInUse              = 911009,
    WebClientStatusFailVerfiedNumberInUse    = 911010,
    WebClientStatusFailCallbackAlreadyActive = 911011,
    WebClientStatusFailNoCallbackFound       = 911012,
    WebClientStatusFailNoCredit              = 911013,
    WebClientStatusFailUnknownCallerId       = 911014,  // Callback: When caller ID is unknown on server.
    WebClientStatusFailUnknownVerifiedNumber = 911015,  // Callback: When called back number is unknown.
    WebClientStatusFailUnknownBothE164       = 911016,  // Callback: When both called ID and called back number unknown.
    WebClientStatusFailNoAccount             = 911051,  // Indirect: not sent by server.
    WebClientStatusFailUnspecified           = 911052,  // Indirect: not sent by server.
    WebClientStatusFailInvalidResponse       = 911053,  // Indirect: not sent by server.
    WebClientStatusFailUnknown               = 911054,  // Extreme unlikely situation where AFNetworking gives failure with error == nil.
} WebClientStatus;


@interface WebClient : AFHTTPClient

+ (WebClient*)sharedClient;


#pragma mark - Request Methods

// 1. CREATE/UPDATE ACCOUNT
- (void)retrieveAccountsForReceipt:(NSString*)receipt
                          language:(NSString*)language
                 notificationToken:(NSString*)notificationToken
                 mobileCountryCode:(NSString*)mobileCountryCode
                 mobileNetworkCode:(NSString*)mobileNetworkCode
                             reply:(void (^)(NSError*  error,
                                             NSString* webUsername,
                                             NSString* webPassword,
                                             NSString* sipUsername,
                                             NSString* sipPassword,
                                             NSString* sipRealm))reply;

// 2A. DO NUMBER VERIFICATION
- (void)retrieveVerificationCodeForE164:(NSString*)e164
                              phoneName:(NSString*)phoneName
                                  reply:(void (^)(NSError* error, NSString* code))reply;

// 2B. DO NUMBER VERIFICATION
- (void)requestVerificationCallForE164:(NSString*)e164
                                 reply:(void (^)(NSError* error))reply;

// 2C. DO NUMBER VERIFICATION
- (void)retrieveVerificationStatusForE164:(NSString*)e164
                                    reply:(void (^)(NSError* error, BOOL calling, BOOL verified))reply;

// 2D. UPDATE VERIFIED NUMBER
- (void)updateVerifiedE164:(NSString*)e164 withName:(NSString*)name reply:(void (^)(NSError* error))reply;

// 3. GET VERIFIED NUMBER LIST
- (void)retrieveVerifiedE164List:(void (^)(NSError* error, NSArray* e164s))reply;

// 4. GET VERIFIED NUMBER INFO
- (void)retrieveVerifiedE164:(NSString*)e164
                       reply:(void (^)(NSError* error, NSString* name))reply;

// 5. DELETE VERIFIED NUMBER
- (void)deleteVerifiedE164:(NSString*)e164
                     reply:(void (^)(NSError*))reply;

// 6. GET LIST OF ALL AVAILABLE NUMBER COUNTRIES
- (void)retrieveNumberCountries:(void (^)(NSError* error, NSArray* countries))reply;

// 7. GET LIST OF ALL AVAILABLE NUMBER STATES
- (void)retrieveNumberStatesForIsoCountryCode:(NSString*)isoCountryCode
                                        reply:(void (^)(NSError* error, NSArray* states))reply;

// 8A. GET LIST OF ALL AVAILABLE NUMBER AREAS (WITH STATES)
- (void)retrieveNumberAreasForIsoCountryCode:(NSString*)isoCountryCode
                                   stateCode:(NSString*)stateCode
                              numberTypeMask:(NumberTypeMask)numberTypeMask
                                currencyCode:(NSString*)currencyCode
                                       reply:(void (^)(NSError* error, NSArray* areas))reply;

// 8B. GET LIST OF ALL AVAILABLE NUMBER AREAS
- (void)retrieveNumberAreasForIsoCountryCode:(NSString*)isoCountryCode
                              numberTypeMask:(NumberTypeMask)numberTypeMask
                                currencyCode:(NSString*)currencyCode
                                       reply:(void (^)(NSError* error, NSArray* areas))reply;

//  9. GET PURCHASE INFO DATA
- (void)retrieveNumberAreaInfoForIsoCountryCode:(NSString*)isoCountryCode
                                       areaCode:(NSString*)areaCode
                                          reply:(void (^)(NSError* error, NSArray* areaInfo))reply;

// 10. CHECK IF PURCHASE INFO IS VALID
- (void)checkPurchaseInfo:(NSDictionary*)info
                    reply:(void (^)(NSError* error, BOOL isValid))reply;

// 11A. PURCHASE NUMBER
- (void)purchaseNumberForReceipt:(NSString*)receipt
                       productId:(NSString*)productId
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
- (void)updateNumberE164:(NSString*)e164 withName:(NSString*)name reply:(void (^)(NSError* error))reply;

// 12. GET LIST OF NUMBERS
- (void)retrieveNumberE164List:(void (^)(NSError* error, NSArray* e164s))reply;

// 13. GET NUMBER INFO
- (void)retrieveNumberE164:(NSString*)e164
              currencyCode:(NSString*)currencyCode
                     reply:(void (^)(NSError* error,
                                     NSString* name,
                                     NSString* numberType,
                                     NSString* areaCode,
                                     NSString* areaName,
                                     NSString* numberCountry,
                                     NSDate*   purchaseDate,
                                     NSDate*   renewalDate,
                                     NSString* salutation,
                                     NSString* firstName,
                                     NSString* lastName,
                                     NSString* company,
                                     NSString* street,
                                     NSString* building,
                                     NSString* city,
                                     NSString* zipCode,
                                     NSString* stateName,
                                     NSString* stateCode,
                                     NSString* addressCountry,
                                     NSData*   proofImage,
                                     BOOL      proofAccepted))reply;

// 14. BUY CREDIT
- (void)purchaseCreditForReceipt:(NSString*)receipt
                    currencyCode:(NSString*)currencyCode
                           reply:(void (^)(NSError* error, float credit))reply;

// 15. GET CURRENT CREDIT
- (void)retrieveCreditForCurrencyCode:(NSString*)currencyCode
                                reply:(void (^)(NSError* error, float credit))reply;

// 16. GET CALL RATE (PER MINUTE)
- (void)retrieveCallRateForE164:(NSString*)e164 currencyCode:(NSString*)currencyCode
                          reply:(void (^)(NSError* error, float ratePerMinute))reply;

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
- (void)retrieveIvrList:(void (^)(NSError* error, NSArray* uuids))reply;

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
                               reply:(void (^)(NSError* error, CallState state, int duration))reply;


#pragma mark - Cancel Methods

// 1.
- (void)cancelAllRetrieveWebAccount;

// 2A.
- (void)cancelAllRetrieveVerificationCode;

// 2B.
- (void)cancelAllRequestVerificationCall;

// 2C.
- (void)cancelAllRetrieveVerificationStatus;

// 2D.
- (void)cancelAllUpdateVerifiedE164:(NSString*)e164;

// 3.
- (void)cancelAllRetrieveVerifiedE164List;

// 4.
- (void)cancelAllRetrieveVerifiedE164:(NSString*)e164;

// 5.
- (void)cancelAllDeleteVerifiedE164:(NSString*)e164;

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
- (void)cancelAllRetrieveNumberE164List;

// 13.
- (void)cancelAllRetrieveNumberE164:(NSString*)e164;

// 14.
- (void)cancelAllPurchaseCredit;

// 15.
- (void)cancelAllRetrieveCredit;

// 16.
- (void)cancelAllRetrieveCallRateForE164:(NSString*)e164;

// 32.
- (void)cancelAllInitiateCallback;

// 33.
- (void)cancelAllStopCallbackForUuid:(NSString*)uuid;

// 34.
- (void)cancelAllRetrieveCallbackStateForUuid:(NSString*)uuid;

@end
