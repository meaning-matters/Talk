//
//  WebClient.h
//  Talk
//
//  Created by Cornelis van der Bent on 10/01/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//
//  List of errors: https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Miscellaneous/Foundation_Constants/Reference/reference.html#//apple_ref/doc/uid/TP40003793-CH3g-SW40

#import <Foundation/Foundation.h>
#import "NumberType.h"
#import "Call.h"
#import "WebStatus.h"
#import "AddressStatus.h"
#import "AddressType.h"


@interface WebClient : NSObject

+ (WebClient*)sharedClient;


#pragma mark - Request Methods

// 0A. GET CALL RATES
- (void)retrieveCallRates:(void (^)(NSError* error, NSArray* rates))reply;

// 0B. GET NUMBER RATES
- (void)retrieveNumberRates:(void (^)(NSError* error, NSArray* rates))reply;

// 1A. CREATE/UPDATE ACCOUNT
- (void)retrieveAccountForReceipt:(NSString*)receipt
                         language:(NSString*)language
                notificationToken:(NSString*)notificationToken
                mobileCountryCode:(NSString*)mobileCountryCode
                mobileNetworkCode:(NSString*)mobileNetworkCode
                       deviceName:(NSString*)deviceName
                         deviceOs:(NSString*)deviceOs
                      deviceModel:(NSString*)deviceModel
                       appVersion:(NSString*)appVersion
                         vendorId:(NSString*)vendorId
                            reply:(void (^)(NSError*  error,
                                            NSString* webUsername,
                                            NSString* webPassword))reply;

// 1B. UPDATE DEVICE INFORMATION
- (void)updateAccountForLanguage:(NSString*)language
                 notificationToken:(NSString*)notificationToken
                 mobileCountryCode:(NSString*)mobileCountryCode
                 mobileNetworkCode:(NSString*)mobileNetworkCode
                        deviceName:(NSString*)deviceName
                          deviceOs:(NSString*)deviceOs
                       deviceModel:(NSString*)deviceModel
                        appVersion:(NSString*)appVersion
                          vendorId:(NSString*)vendorId
                             reply:(void (^)(NSError*  error,
                                             NSString* webUsername,
                                             NSString* webPassword))reply;

// 2A. DO NUMBER VERIFICATION
- (void)retrievePhoneVerificationCodeForE164:(NSString*)e164
                                       reply:(void (^)(NSError* error, NSString* code))reply;

// 2B. DO NUMBER VERIFICATION
- (void)requestPhoneVerificationCallForE164:(NSString*)e164
                                 reply:(void (^)(NSError* error))reply;

// 2C. DO NUMBER VERIFICATION
- (void)retrievePhoneVerificationStatusForE164:(NSString*)e164
                                    reply:(void (^)(NSError* error, BOOL calling, BOOL verified))reply;

// 2D. STOP VERIFICATION
- (void)stopPhoneVerificationForE164:(NSString*)e164 reply:(void (^)(NSError* error))reply;

// 2E. UPDATE VERIFIED NUMBER
- (void)updatePhoneVerificationForE164:(NSString*)e164 name:(NSString*)name reply:(void (^)(NSError* error))reply;

// 3. GET VERIFIED NUMBER LIST
- (void)retrievePhonesList:(void (^)(NSError* error, NSArray* e164s))reply;

// 4. GET VERIFIED NUMBER INFO
- (void)retrievePhoneWithE164:(NSString*)e164
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

// 10A. GET LIST OF REGULATION ADDRESSES
- (void)retrieveAddressesForIsoCountryCode:(NSString*)isoCountryCode        // Optional (i.e. can be nil).
                                  areaCode:(NSString*)areaCode              // Optional (i.e. can be nil).
                                numberType:(NumberTypeMask)numberTypeMask   // Mandatory.
                           isExtranational:(BOOL)isExtranational
                                     reply:(void (^)(NSError* error, NSArray* addressIds))reply;

// 10B. GET REGULATION ADDRESS
- (void)retrieveAddressWithId:(NSString*)addressId
                        reply:(void (^)(NSError*            error,
                                        NSString*           name,
                                        NSString*           salutation,
                                        NSString*           firstName,
                                        NSString*           lastName,
                                        NSString*           companyName,
                                        NSString*           companyDescription,
                                        NSString*           street,
                                        NSString*           buildingNumber,
                                        NSString*           buildingLetter,
                                        NSString*           city,
                                        NSString*           postcode,
                                        NSString*           isoCountryCode,
                                        BOOL                hasProof,
                                        NSString*           idType,
                                        NSString*           idNumber,
                                        NSString*           fiscalIdCode,
                                        NSString*           streetCode,
                                        NSString*           municipalityCode,
                                        AddressStatusMask   addressStatus,
                                        RejectionReasonMask rejectionReasons))reply;

// 10C. CREATE REGULATION ADDRESS
- (void)createAddressForIsoCountryCode:(NSString*)numberIsoCountryCode
                            numberType:(NumberTypeMask)numberTypeMask
                                  name:(NSString*)name
                            salutation:(NSString*)salutation
                             firstName:(NSString*)firstName
                              lastName:(NSString*)lastName
                           companyName:(NSString*)companyName
                    companyDescription:(NSString*)companyDescription
                                street:(NSString*)street
                        buildingNumber:(NSString*)buildingNumber
                        buildingLetter:(NSString*)buildingLetter
                                  city:(NSString*)city
                              postcode:(NSString*)postcode
                        isoCountryCode:(NSString*)isoCountryCode
                            proofImage:(NSData*)proofImage
                                idType:(NSString*)idType
                              idNumber:(NSString*)idNumber
                          fiscalIdCode:(NSString*)fiscalIdCode
                            streetCode:(NSString*)streetCode
                      municipalityCode:(NSString*)municipalityCode
                                 reply:(void (^)(NSError*  error,
                                                 NSString* addressId,
                                                 NSString* addressStatus,
                                                 NSArray*  missingFields))reply;

// 10D. DELETE REGULATION ADDRESS
- (void)deleteAddressWithId:(NSString*)addressId
                      reply:(void (^)(NSError* error))reply;

// 10E. GET ADDRESS PROOF IMAGE
- (void)retrieveImageForAddressId:(NSString*)addressId
                            reply:(void (^)(NSError* error, NSData* proofImage))reply;

// 10F. UPDATE ADDRESS PROOF IMAGE
- (void)updateImageForAddressId:(NSString*)addressId
                          reply:(void (^)(NSError* error))reply;

// 10G. UPDATE ADDRESS' NAME
- (void)updateAddressWithId:(NSString*)addressId withName:(NSString*)name reply:(void (^)(NSError* error))reply;

// 11A. PURCHASE NUMBER
- (void)purchaseNumberForMonths:(NSUInteger)months
                           name:(NSString*)name
                 isoCountryCode:(NSString*)isoCountryCode
                         areaId:(NSString*)areaId
                      addressId:(NSString*)addressId
                      autoRenew:(BOOL)autoRenew
                          reply:(void (^)(NSError* error, NSString* e164, NSDate* purchaseDate, NSDate* renewalDate))reply;

// 11B. UPDATE NUMBER'S NAME
- (void)updateNumberE164:(NSString*)e164
                withName:(NSString*)name
               autoRenew:(BOOL)autoRenew
               addressId:(NSString*)addressId
                   reply:(void (^)(NSError* error))reply;

// 11C. EXTEND NUMBER
- (void)extendNumberE164:(NSString*)e164 forMonths:(NSUInteger)months reply:(void (^)(NSError* error))reply;

// 12. GET LIST OF NUMBERS
- (void)retrieveNumbersList:(void (^)(NSError* error, NSArray* e164s))reply;

// 13. GET NUMBER INFO
- (void)retrieveNumberWithE164:(NSString*)e164
                         reply:(void (^)(NSError*        error,
                                         NSString*       name,
                                         NSString*       numberType,
                                         NSString*       areaCode,
                                         NSString*       areaName,
                                         NSString*       stateCode,
                                         NSString*       stateName,
                                         NSString*       isoCountryCode,
                                         NSString*       addressId,
                                         AddressTypeMask addressType,
                                         NSDictionary*   proofTypes,
                                         NSDate*         purchaseDate,
                                         NSDate*         renewalDate,
                                         BOOL            autoRenew,
                                         float           fixedRate,
                                         float           fixedSetup,
                                         float           mobileRate,
                                         float           mobileSetup,
                                         float           payphoneRate,
                                         float           payphoneSetup,
                                         float           monthFee,
                                         float           renewFee))reply;

// 14. BUY CREDIT
- (void)purchaseCreditForReceipt:(NSString*)receipt
                           reply:(void (^)(NSError* error, float credit))reply;

// 15. GET CURRENT CREDIT
- (void)retrieveCreditWithReply:(void (^)(NSError* error, float credit))reply;

// 16. GET CALL RATE (PER MINUTE)
- (void)retrieveCallRateForE164:(NSString*)e164
                          reply:(void (^)(NSError* error, float ratePerMinute))reply;

// 19A. CREATE DESTINATION
- (void)createDestinationWithName:(NSString*)name
                           action:(NSDictionary*)action
                            reply:(void (^)(NSError* error, NSString* uuid))reply;

// 19B. UPDATE DESTINATION
- (void)updateDestinationForUuid:(NSString*)uuid
                            name:(NSString*)name
                          action:(NSDictionary*)action
                           reply:(void (^)(NSError* error))reply;

// 20. DELETE DESTINATION
- (void)deleteDestinationForUuid:(NSString*)uuid
                           reply:(void (^)(NSError* error))reply;

// 21. GET LIST OF DESTINATIONS
- (void)retrieveDestinationsList:(void (^)(NSError* error, NSArray* uuids))reply;

// 22. DOWNLOAD DESTINATION
- (void)retrieveDestinationForUuid:(NSString*)uuid
                             reply:(void (^)(NSError* error, NSString* name, NSDictionary* action))reply;

// 23. SET/CLEAR DESTINATION FOR A NUMBER
- (void)setDestinationOfE164:(NSString*)e164
                        uuid:(NSString*)uuid
                       reply:(void (^)(NSError* error))reply;

// 24. RETRIEVE DESTINATION FOR A NUMBER
- (void)retrieveDestinationOfE164:(NSString*)e164
                            reply:(void (^)(NSError* error, NSString* uuid))reply;

// 25. UPDATE AUDIO
- (void)updateAudioForUuid:(NSString*)uuid
                      data:(NSData*)data
                      name:(NSString*)name
                     reply:(void (^)(NSError* error))reply;

// 26. DOWNLOAD AUDIO
- (void)retrieveAudioForUuid:(NSString*)uuid
                       reply:(void (^)(NSError*  error,
                                       NSString* name,
                                       NSData*   data))reply;

// 27. DELETE AUDIO
- (void)deleteAudioForUuid:(NSString*)uuid
                     reply:(void (^)(NSError*  error))reply;

// 28. GET LIST OF AUDIO UUID'S
- (void)retrieveAudioList:(void (^)(NSError* error, NSArray* uuids))reply;

// 29. CREATE AUDIO
- (void)createAudioWithData:(NSData*)data
                       name:(NSString*)name
                      reply:(void (^)(NSError* error, NSString* uuid))reply;

// 32. INITIATE CALLBACK
- (void)initiateCallbackForCallbackE164:(NSString*)callbackE164
                           callthruE164:(NSString*)callthruE164
                           identityE164:(NSString*)identityE164
                                privacy:(BOOL)privacy
                                  reply:(void (^)(NSError* error, NSString* uuid))reply;

// 33. STOP CALLBACK
- (void)stopCallbackForUuid:(NSString*)uuid
                      reply:(void (^)(NSError* error))reply;

// 34. GET CALLBACK STATE
- (void)retrieveCallbackStateForUuid:(NSString*)uuid
                               reply:(void (^)(NSError*  error,
                                               CallState state,
                                               CallLeg   leg,
                                               int       callbackDuration,
                                               int       callthruDuration,
                                               float     callbackCost,
                                               float     callthruCost))reply;

#pragma mark - Cancel Methods

// 0A.
- (void)cancelAllRetrieveCallRates;

// 0B.
- (void)cancelAllRetrieveNumberRates;

// 1.
- (void)cancelAllRetrieveWebAccount;

// 2A.
- (void)cancelAllRetrievePhoneVerificationCode;

// 2B.
- (void)cancelAllRequestPhoneVerificationCall;

// 2C.
- (void)cancelAllRetrievePhoneVerificationStatus;

// 2D.
- (void)cancelAllStopPhoneVerification;

// 2E.
- (void)cancelAllUpdatePhoneVerificationForE164:(NSString*)e164;

// 3.
- (void)cancelAllRetrievePhonesList;

// 4.
- (void)cancelAllRetrievePhoneWithE164:(NSString*)e164;

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

// 10A.
- (void)cancelAllRetrieveAddresses;

// 10B.
- (void)cancelAllRetrieveAddressWithId:(NSString*)addressId;

// 10C.
- (void)cancelAllCreateAddress;

// 10D.
- (void)cancelAllDeleteAddressWithId:(NSString*)addressId;

// 10E.
- (void)cancelAllRetrieveImageForAddressId:(NSString*)addressId;

// 10F.
- (void)cancelAllUpdateImageForAddressId:(NSString*)addressId;

// 11A.
- (void)cancelAllPurchaseNumber;

// 11B.
- (void)cancelAllUpdateNumberWithE164:(NSString*)e164;

// 11C.
- (void)cancelAllExtendNumberWithE164:(NSString*)e164;

// 12.
- (void)cancelAllRetrieveNumbersList;

// 13.
- (void)cancelAllRetrieveNumberWithE164:(NSString*)e164;

// 14.
- (void)cancelAllPurchaseCredit;

// 15.
- (void)cancelAllRetrieveCredit;

// 16.
- (void)cancelAllRetrieveCallRateForE164:(NSString*)e164;

// 19.
- (void)cancelAllCreateDestinationForUuid:(NSString*)uuid;

// 20.
- (void)cancelAllDeleteDestinationForUuid:(NSString*)uuid;

// 21.
- (void)cancelAllRetrieveDestinationsList;

// 22.
- (void)cancelAllRetrieveDestinationForUuid:(NSString*)uuid;

// 23.
- (void)cancelAllSetDestinationOfE164:(NSString*)e164;

// 25.
- (void)cancellAllUpdateAudioForUuid:(NSString*)uuid;

// 26.
- (void)cancelAllRetrieveAudioForUuid:(NSString*)uuid;

// 27.
- (void)cancelAllDeleteAudioForUuid:(NSString*)uuid;

// 28.
- (void)cancelAllRetrieveAudioList;

// 29.
- (void)cancelAllCreateAudio;

// 32.
- (void)cancelAllInitiateCallback;

// 33.
- (void)cancelAllStopCallbackForUuid:(NSString*)uuid;

// 34.
- (void)cancelAllRetrieveCallbackStateForUuid:(NSString*)uuid;

@end
