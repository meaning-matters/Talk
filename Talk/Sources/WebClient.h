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
#import "MessageData.h"


@interface WebClient : NSObject

+ (WebClient*)sharedClient;


#pragma mark - Utility Method

- (NSDictionary*)restoreE164InAction:(NSDictionary*)action;


#pragma mark - Request Methods

// 0A. GET CALL RATES
- (void)retrieveCallRates:(void (^)(NSError* error, NSArray* rates))reply;

// 0B. GET NUMBER RATES
- (void)retrieveNumberRates:(void (^)(NSError* error, NSArray* rates))reply;

// OC. GET OPTIONS
- (void)retrieveOptions:(void (^)(NSError* error, BOOL freeAccount))reply;

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
                                            NSString* webPassword,
                                            NSString* accountId))reply;

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
                                           NSString* webPassword,
                                           NSString* accountId,
                                           BOOL      mustUpdateApp))reply;

// 2A. BEGIN NUMBER VERIFICATION
- (void)beginPhoneVerificationForE164:(NSString*)e164 mode:(NSString*)mode
                                reply:(void (^)(NSError*  error,
                                                NSString* uuid,
                                                BOOL      verified,
                                                NSString* code,
                                                NSArray*  languageCodes))reply;

// 2B. REQUEST NUMBER VERIFICATION CALL
- (void)requestPhoneVerificationCallForUuid:(NSString*)uuid reply:(void (^)(NSError* error))reply;

// 2C. REQUEST NUMBER VERIFICATION STATUS
- (void)retrievePhoneVerificationStatusForUuid:(NSString*)uuid
                                         reply:(void (^)(NSError* error, BOOL isCalling, BOOL isVerified))reply;

// 2D. REQUEST NUMBER VERIFICATION CANCEL
- (void)stopPhoneVerificationForUuid:(NSString*)uuid reply:(void (^)(NSError* error))reply;

// 2E. UPDATE VERIFIED NUMBER
- (void)updatePhoneVerificationForUuid:(NSString*)uuid name:(NSString*)name reply:(void (^)(NSError* error))reply;

// 2F. CHECK VOICE VERIFICATION CODE
- (void)checkVoiceVerificationCode:(NSString*)code
                           forUuid:(NSString*)uuid
                             reply:(void (^)(NSError* error, BOOL isVerified))reply;

// 3. GET VERIFIED NUMBER LIST
- (void)retrievePhones:(void (^)(NSError* error, NSArray* phones))reply;

// 4. GET VERIFIED NUMBER INFO
- (void)retrievePhoneWithUuid:(NSString*)uuid reply:(void (^)(NSError* error, NSString* e164, NSString* name))reply;

// 5. DELETE VERIFIED NUMBER
- (void)deletePhoneWithUuid:(NSString*)uuid reply:(void (^)(NSError*))reply;

// 6A. GET LIST OF ALL AVAILABLE NUMBER COUNTRIES
- (void)retrieveNumberCountries:(void (^)(NSError* error, NSArray* countries))reply;

// 6B. GET NUMBER COUNTRY INFO
- (void)retrieveNumberCountryWithIsoCountryCode:(NSString*)isoCountryCode
                                          reply:(void (^)(NSError* error, NSArray* countryInfo))reply;

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

// 9. GET PURCHASE INFO DATA
- (void)retrieveNumberAreaInfoForIsoCountryCode:(NSString*)isoCountryCode
                                         areaId:(NSString*)areaId
                                          reply:(void (^)(NSError*        error,
                                                          NSArray*        cities,
                                                          AddressTypeMask addressType,
                                                          BOOL            alwaysRequired,
                                                          NSDictionary*   personRegulations,
                                                          NSDictionary*   companyRegulations))reply;

// 10. CHECK IF PURCHASE INFO IS VALID
- (void)checkPurchaseInfo:(NSDictionary*)info reply:(void (^)(NSError* error, BOOL isValid))reply;

// 10A. GET LIST OF REGULATION ADDRESSES
- (void)retrieveAddressesForIsoCountryCode:(NSString*)isoCountryCode        // Optional (i.e. can be nil).
                                  areaCode:(NSString*)areaCode              // Optional (i.e. can be nil).
                                numberType:(NumberTypeMask)numberTypeMask   // Mandatory.
                           isExtranational:(BOOL)isExtranational
                                     reply:(void (^)(NSError* error, NSArray* addresses))reply;

// 10B. GET REGULATION ADDRESS
- (void)retrieveAddressWithUuid:(NSString*)uuid imageless:(BOOL)imageless
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
                                          NSString*           areaCode,
                                          NSString*           addressProofMd5,
                                          NSString*           identityProofMd5,
                                          NSData*             addressProof,
                                          NSData*             identityProof,
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
                              areaCode:(NSString*)areaCode
                          addressProof:(NSData*)addressProof
                         identityProof:(NSData*)identityProof
                           nationality:(NSString*)nationality   // Also an ISO-2 cpountry code.
                                idType:(NSString*)idType
                              idNumber:(NSString*)idNumber
                          fiscalIdCode:(NSString*)fiscalIdCode
                            streetCode:(NSString*)streetCode
                      municipalityCode:(NSString*)municipalityCode
                                 reply:(void (^)(NSError*  error,
                                                 NSString* uuid,
                                                 NSString* addressStatus,
                                                 NSArray*  missingFields))reply;

// 10D. DELETE REGULATION ADDRESS
- (void)deleteAddressWithUuid:(NSString*)uuid
                        reply:(void (^)(NSError* error))reply;

// 10G. UPDATE ADDRESS' NAME
- (void)updateAddressWithUuid:(NSString*)uuid
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
                 addressProof:(NSData*)addressProof
                identityProof:(NSData*)identityProof
                       idType:(NSString*)idType
                     idNumber:(NSString*)idNumber
                 fiscalIdCode:(NSString*)fiscalIdCode
                   streetCode:(NSString*)streetCode
             municipalityCode:(NSString*)municipalityCode
                        reply:(void (^)(NSError*  error,
                                        NSString* addressStatus))reply;

// 11A. PURCHASE NUMBER
- (void)purchaseNumberForMonths:(NSUInteger)months
                           name:(NSString*)name
                 isoCountryCode:(NSString*)isoCountryCode
                         areaId:(NSString*)areaId
                    addressUuid:(NSString*)addressUuid
                      autoRenew:(BOOL)autoRenew
                          reply:(void (^)(NSError*  error,
                                          NSString* uuid,
                                          NSString* e164,
                                          NSDate*   purchaseDate,
                                          NSDate*   expiryDate,
                                          float     monthFee,
                                          float     renewFee))reply;

// 11B. UPDATE NUMBER ATTRIBUTES
- (void)updateNumberWithUuid:(NSString*)uuid
                        name:(NSString*)name
                   autoRenew:(BOOL)autoRenew
             destinationUuid:(NSString*)destinationUuid
                 addressUuid:(NSString*)addressUuid
                       reply:(void (^)(NSError*  error,
                                       NSString* e164,            // This and the values below will only be returned
                                       NSDate*   purchaseDate,    // when the Number was purchased as a result of
                                       NSDate*   expiryDate,      // selecting a verified Address.
                                       float     monthFee,        //
                                       float     renewFee))reply; //

// 11C. EXTEND NUMBER
- (void)extendNumberWithUuid:(NSString*)uuid
                   forMonths:(NSUInteger)months
                       reply:(void (^)(NSError* error,
                                       float    monthFee,
                                       float    renewFee,
                                       NSDate*  expiryDate))reply;

// 11D. DELETE PENDING NUMBER
- (void)deleteNumberWithUuid:(NSString*)uuid
                       reply:(void (^)(NSError* error))reply;

// 12. GET LIST OF NUMBERS
- (void)retrieveNumbers:(void (^)(NSError* error, NSArray* numbers))reply;

// 13. GET NUMBER INFO
- (void)retrieveNumberWithUuid:(NSString*)uuid
                         reply:(void (^)(NSError*        error,
                                         NSString*       e164,
                                         NSString*       name,
                                         NSString*       numberType,
                                         NSString*       areaCode,
                                         NSString*       areaName,
                                         NSString*       areaId,
                                         NSString*       stateCode,
                                         NSString*       stateName,
                                         NSString*       isoCountryCode,
                                         NSString*       addressUuid,
                                         AddressTypeMask addressType,
                                         NSDate*         purchaseDate,
                                         NSDate*         expiryDate,
                                         BOOL            autoRenew,
                                         NSString*       destinationUuid,
                                         float           fixedRate,
                                         float           fixedSetup,
                                         float           mobileRate,
                                         float           mobileSetup,
                                         float           payphoneRate,
                                         float           payphoneSetup,
                                         float           monthFee,
                                         float           renewFee))reply;

// 14. BUY CREDIT
- (void)purchaseCreditForReceipt:(NSString*)receipt reply:(void (^)(NSError* error, float credit))reply;

// 15. GET CURRENT CREDIT
- (void)retrieveCreditWithReply:(void (^)(NSError* error, float credit))reply;

// 16. GET CALL RATE (PER MINUTE)
- (void)retrieveCallRateForE164:(NSString*)e164 reply:(void (^)(NSError* error, float ratePerMinute))reply;

// 17. GET CDRS
- (void)retrieveCallRecordsFromDate:(NSDate*)date
                            inbound:(BOOL)inbound
                           outbound:(BOOL)outbound
                       verification:(BOOL)verification
                              reply:(void (^)(NSError* error, NSArray* records))reply;

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
- (void)deleteDestinationForUuid:(NSString*)uuid reply:(void (^)(NSError* error))reply;

// 21. GET LIST OF DESTINATIONS
- (void)retrieveDestinations:(void (^)(NSError* error, NSArray* destinations))reply;

// 22. DOWNLOAD DESTINATION
- (void)retrieveDestinationForUuid:(NSString*)uuid
                             reply:(void (^)(NSError* error, NSString* name, NSDictionary* action))reply;

// 25. UPDATE AUDIO
- (void)updateAudioForUuid:(NSString*)uuid
                      data:(NSData*)data
                      name:(NSString*)name
                     reply:(void (^)(NSError* error))reply;

// 26. DOWNLOAD AUDIO
- (void)retrieveAudioForUuid:(NSString*)uuid reply:(void (^)(NSError* error, NSString* name, NSData* data))reply;

// 27. DELETE AUDIO
- (void)deleteAudioForUuid:(NSString*)uuid reply:(void (^)(NSError* error))reply;

// 28. GET LIST OF AUDIO UUID'S
- (void)retrieveAudios:(void (^)(NSError* error, NSArray* audios))reply;

// 29. CREATE AUDIO
- (void)createAudioWithData:(NSData*)data name:(NSString*)name reply:(void (^)(NSError* error, NSString* uuid))reply;

// 32. INITIATE CALLBACK
- (void)initiateCallbackForCallbackE164:(NSString*)callbackE164
                           callthruE164:(NSString*)callthruE164
                           identityE164:(NSString*)identityE164
                                privacy:(BOOL)privacy
                                  reply:(void (^)(NSError* error, NSString* uuid))reply;

// 33. STOP CALLBACK
- (void)stopCallbackForUuid:(NSString*)uuid reply:(void (^)(NSError* error))reply;

// 34. GET CALLBACK STATE
- (void)retrieveCallbackStateForUuid:(NSString*)uuid
                               reply:(void (^)(NSError*  error,
                                               CallState state,
                                               CallLeg   leg,
                                               int       callbackDuration,
                                               int       callthruDuration,
                                               float     callbackCost,
                                               float     callthruCost))reply;

// Get all messages - /users/{user_id}/messages
// 40A. GET ALL MESSAGES
- (void)retrieveMessages:(void (^)(NSError* error, NSArray* messages))reply;


// 40B. SEND SMS
- (void)sendMessage:(MessageData*)message reply:(void(^)(NSError* error, NSString* uuid))reply;



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
- (void)cancelAllRequestPhoneVerificationCallForUuid:(NSString*)uuid;

// 2C.
- (void)cancelAllRetrievePhoneVerificationStatusForUuid:(NSString*)uuid;

// 2D.
- (void)cancelAllStopPhoneVerificationForUuid:(NSString*)uuid;

// 2E.
- (void)cancelAllUpdatePhoneVerificationForUuid:(NSString*)uuid;

// 2F.
- (void)cancelAllCheckVoiceVerificationCodeForUuid:(NSString*)uuid;

// 3.
- (void)cancelAllRetrievePhonesList;

// 4.
- (void)cancelAllRetrievePhoneWithUuid:(NSString*)uuid;

// 5.
- (void)cancelAllDeletePhoneWithUuid:(NSString*)uuid;

// 6A.
- (void)cancelAllRetrieveNumberCountries;

// 6B.
- (void)cancelAllRetrieveNumberCountryWithIsoCountryCode:(NSString*)isoCountryCode;

// 7.
- (void)cancelAllRetrieveNumberStatesForIsoCountryCode:(NSString*)isoCountryCode;

// 8A.
- (void)cancelAllRetrieveNumberAreasForIsoCountryCode:(NSString*)isoCountryCode stateCode:(NSString*)stateCode;

// 8B.
- (void)cancelAllRetrieveNumberAreasForIsoCountryCode:(NSString*)isoCountryCode;

// 9.
- (void)cancelAllRetrieveAreaInfoForIsoCountryCode:(NSString*)isoCountryCode areaId:(NSString*)areaId;

// 10.
- (void)cancelAllCheckPurchaseInfo;

// 10A.
- (void)cancelAllRetrieveAddresses;

// 10B.
- (void)cancelAllRetrieveAddressWithUuid:(NSString*)uuid;

// 10C.
- (void)cancelAllCreateAddress;

// 10D.
- (void)cancelAllDeleteAddressWithUuid:(NSString*)uuid;

// 11A.
- (void)cancelAllPurchaseNumber;

// 11B.
- (void)cancelAllUpdateNumberWithUuid:(NSString*)uuid;

// 11C.
- (void)cancelAllExtendNumberWithUuid:(NSString*)uuid;

// 12.
- (void)cancelAllRetrieveNumbersList;

// 13.
- (void)cancelAllRetrieveNumberWithUuid:(NSString*)uuid;

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

// 40A.
- (void)cancelAllRetrieveChats;

// 40A
- (void)cancelAllRetrieveMessages;

// 40B.
//- (void)cancelAllCreateMessageWithDestination:(NSString*)e164;





@end
