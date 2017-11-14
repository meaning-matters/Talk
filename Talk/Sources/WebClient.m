//
//  WebClient.m
//  Talk
//
//  Created by Cornelis van der Bent on 10/01/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//
//  See link below for all URL load error codes and give more details than WebStatusFailNetworkProblem:
//  https://developer.apple.com/library/mac/#documentation/Cocoa/Reference/Foundation/Miscellaneous/Foundation_Constants/Reference/reference.html


#import "WebClient.h"
#import "WebInterface.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "AnalyticsTransmitter.h"
#import "Settings.h"
#import "Common.h"
#import "PurchaseManager.h"
#import "Base64.h"

#define BOOLEAN(value) (value) ? @"true" : @"false"


@interface WebClient ()

@property (nonatomic, strong) WebInterface* webInterface;

@end


@implementation WebClient

#pragma mark - Singleton Stuff

+ (WebClient*)sharedClient
{
    static WebClient*      sharedInstance;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^
    {
        sharedInstance              = [[self alloc] init];

        sharedInstance.webInterface = [WebInterface sharedInterface];
    });

    return sharedInstance;
}


#pragma mark - Helpers

- (BOOL)handleAccount:(void (^)(NSError* error, id content))reply
{
    if ([Settings sharedSettings].haveAccount == NO)
    {
        WebStatusCode code = WebStatusFailNoAccount;
        reply([Common errorWithCode:code description:[WebStatus localizedStringForStatus:code]], nil);
    }
    
    return [Settings sharedSettings].haveAccount;
}


- (void)postPath:(NSString*)path
      parameters:(NSDictionary*)parameters
           reply:(void (^)(NSError* error, id content))reply
{
    if ([self handleAccount:reply] == NO)
    {
        return;
    }

    [self.webInterface postPath:path parameters:parameters reply:reply];
}


- (void)putPath:(NSString*)path
     parameters:(NSDictionary*)parameters
          reply:(void (^)(NSError* error, id content))reply
{
    if ([self handleAccount:reply] == NO)
    {
        return;
    }

    [self.webInterface putPath:path parameters:parameters reply:reply];
}


- (void)getPath:(NSString*)path
     parameters:(NSDictionary*)parameters
          reply:(void (^)(NSError* error, id content))reply
{
    if ([self handleAccount:reply] == NO)
    {
        return;
    }

    [self.webInterface getPath:path parameters:parameters reply:reply];
}


- (void)deletePath:(NSString*)path
        parameters:(NSDictionary*)parameters
             reply:(void (^)(NSError* error, id content))reply
{
    if ([self handleAccount:reply] == NO)
    {
        return;
    }

    [self.webInterface deletePath:path parameters:parameters reply:reply];
}


- (NSDictionary*)stripE164InAction:(NSDictionary*)action
{
    NSMutableDictionary* mutableAction = [Common mutableObjectWithJsonString:[Common jsonStringWithObject:action]];

    [self traverseStatements:mutableAction strip:YES];

    return mutableAction;
}


- (NSDictionary*)restoreE164InAction:(NSDictionary*)action
{
    NSMutableDictionary* mutableAction = [Common mutableObjectWithJsonString:[Common jsonStringWithObject:action]];

    [self traverseStatements:mutableAction strip:NO];

    return mutableAction;
}


- (void)traverseStatements:(id)object strip:(BOOL)strip
{
    if ([object isKindOfClass:[NSMutableDictionary class]])
    {
        //### When iterating "for (NSString* key in object)" got app crash.
        //### It occurred only with some Destination JSON; very weird.
        //### http://stackoverflow.com/q/14457369/1971013
        //### Let's see what happens here when we have longer Destinations.
        for (NSString* key in [object allKeys])
        {
            if ([key isEqualToString:@"e164s"])
            {
                NSMutableArray* e164s = [NSMutableArray array];
                for (NSString* e164 in object[key])
                {
                    if (strip)
                    {
                        [e164s addObject:[e164 substringFromIndex:1]];
                    }
                    else
                    {
                        [e164s addObject:[@"+" stringByAppendingString:e164]];
                    }
                }

                object[key] = e164s;
            }
            else if ([key isEqualToString:@"e164"])
            {
                if (strip)
                {
                    object[key] = [object[key] substringFromIndex:1];
                }
                else
                {
                    object[key] = [@"+" stringByAppendingString:object[key]];
                }
            }
            else
            {
                id child = object[key];
                [self traverseStatements:child strip:strip];
            }
        }
    }
    else if ([object isKindOfClass:[NSMutableArray class]])
    {
        for (id child in object)
        {
            [self traverseStatements:child strip:strip];
        }
    }
    else
    {
        // Not a container.
    }
}


#pragma mark - Public API

// 0A. GET CALL RATES
- (void)retrieveCallRates:(void (^)(NSError* error, NSArray* rates))reply
{
    NSString* currencyCode = [Settings sharedSettings].storeCurrencyCode;
    NSString* countryCode  = [Settings sharedSettings].storeCountryCode;
    
    // Don't call `handleAccount` and get data without needing account.
    
    [self.webInterface getPath:[NSString stringWithFormat:@"/rates/calls?currencyCode=%@&countryCode=%@",
                                                          currencyCode, countryCode]
                    parameters:nil
                         reply:reply];
}


// 0B. GET NUMBER RATES
- (void)retrieveNumberRates:(void (^)(NSError* error, NSArray* rates))reply
{
    NSString* currencyCode = [Settings sharedSettings].storeCurrencyCode;
    NSString* countryCode  = [Settings sharedSettings].storeCountryCode;
    
    // Don't call `handleAccount` and get data without needing account.

    [self.webInterface getPath:[NSString stringWithFormat:@"/rates/numbers?currencyCode=%@&countryCode=%@",
                                                          currencyCode, countryCode]
                    parameters:nil
                         reply:reply];
}


// OC. GET OPTIONS
- (void)retrieveOptions:(void (^)(NSError* error, BOOL freeAccount))reply
{
    // Don't call `handleAccount` and get data without needing account.

    [self.webInterface getPath:@"/options"
                    parameters:nil
                    reply:^(NSError* error, id content)
    {
        reply(error, [content[@"freeAccount"] boolValue]);
    }];
}


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
                                            NSString* accountId))reply
{
    NSDictionary* parameters;
    NSString*     buildType;

#ifdef DEBUG
    buildType = @"debug";
#else
    buildType = @"release";
#endif
    
    if (mobileCountryCode == nil || mobileNetworkCode == nil)
    {
        parameters = @{@"receipt"           : receipt,
                       @"language"          : language,
                       @"notificationToken" : notificationToken,
                       @"deviceName"        : deviceName,
                       @"deviceOs"          : deviceOs,
                       @"deviceModel"       : deviceModel,
                       @"appVersion"        : appVersion,
                       @"buildType"         : buildType,
                       @"vendorId"          : vendorId};
    }
    else
    {
        parameters = @{@"receipt"           : receipt,
                       @"language"          : language,
                       @"notificationToken" : notificationToken,
                       @"mobileCountryCode" : mobileCountryCode,
                       @"mobileNetworkCode" : mobileNetworkCode,
                       @"deviceName"        : deviceName,
                       @"deviceOs"          : deviceOs,
                       @"deviceModel"       : deviceModel,
                       @"appVersion"        : appVersion,
                       @"buildType"         : buildType,
                       @"vendorId"          : vendorId};
    }

    NSString* currencyCode = [Settings sharedSettings].storeCurrencyCode;
    NSString* countryCode  = [Settings sharedSettings].storeCountryCode;
    
    // Don't call `handleAccount` and get data without needing account.

    [self.webInterface postPath:[NSString stringWithFormat:@"/users?currencyCode=%@&countryCode=%@",
                                                           currencyCode, countryCode]
                     parameters:parameters
                          reply:^(NSError *error, id content)
    {
        reply(error, content[@"webUsername"], content[@"webPassword"], [content[@"accountId"] description]);
    }];
}


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
                                           BOOL      mustUpdateApp))reply
{
    NSString*     username = [Settings sharedSettings].webUsername;
    NSDictionary* parameters;
    NSString*     buildType;

#ifdef DEBUG
    buildType = @"debug";
#else
    buildType = @"release";
#endif

    if (mobileCountryCode == nil || mobileNetworkCode == nil)
    {
        parameters = @{@"language"          : language,
                       @"notificationToken" : notificationToken,
                       @"deviceName"        : deviceName,
                       @"deviceOs"          : deviceOs,
                       @"deviceModel"       : deviceModel,
                       @"appVersion"        : appVersion,
                       @"buildType"         : buildType,
                       @"vendorId"          : vendorId};
    }
    else
    {
        parameters = @{@"language"          : language,
                       @"notificationToken" : notificationToken,
                       @"mobileCountryCode" : mobileCountryCode,
                       @"mobileNetworkCode" : mobileNetworkCode,
                       @"deviceName"        : deviceName,
                       @"deviceOs"          : deviceOs,
                       @"deviceModel"       : deviceModel,
                       @"appVersion"        : appVersion,
                       @"buildType"         : buildType,
                       @"vendorId"          : vendorId};
    }
    
    [self putPath:[NSString stringWithFormat:@"/users/%@", username]
       parameters:parameters
            reply:^(NSError *error, id content)
    {
        reply(error,
              content[@"webUsername"],
              content[@"webPassword"],
              [content[@"accountId"] description],
              [content[@"mustUpdateApp"] boolValue]);
    }];
}


// 2A. GET PHONE VERIFICATION CODE
- (void)beginPhoneVerificationForE164:(NSString*)e164 mode:(NSString*)mode
                                reply:(void (^)(NSError*  error,
                                                NSString* uuid,
                                                BOOL      verified,
                                                NSString* code,
                                                NSArray*  languageCodes))reply
{
    NSString*     username   = [Settings sharedSettings].webUsername;
    NSDictionary* parameters = @{@"e164" : [e164 substringFromIndex:1], @"mode" : mode};

    [self postPath:[NSString stringWithFormat:@"/users/%@/phones", username]
        parameters:parameters
             reply:^(NSError* error, id content)
    {
        if (error == nil)
        {
            reply(nil, content[@"uuid"], [content[@"verified"] boolValue], content[@"code"], content[@"languages"]);
        }
        else
        {
            reply(error, nil, NO, nil, nil);
        }
    }];
}


// 2B. REQUEST PHONE VERIFICATION CALL
- (void)requestPhoneVerificationCallForUuid:(NSString*)uuid reply:(void (^)(NSError* error))reply
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self putPath:[NSString stringWithFormat:@"/users/%@/phones/%@/verification", username, uuid]
       parameters:nil
            reply:^(NSError* error, id content)
    {
        reply(error);
    }];
}


// 2C. CHECK PHONE VERIFICATION STATUS
- (void)retrievePhoneVerificationStatusForUuid:(NSString*)uuid
                                         reply:(void (^)(NSError* error, BOOL isCalling, BOOL isVerified))reply
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self getPath:[NSString stringWithFormat:@"/users/%@/phones/%@/verification", username, uuid]
       parameters:nil
            reply:^(NSError* error, id content)
    {
        if (error == nil)
        {
            reply(nil, [content[@"calling"] boolValue], [content[@"verified"] boolValue]);
        }
        else
        {
            reply(error, NO, NO);
        }
    }];
}


// 2D. STOP VERIFICATION
- (void)stopPhoneVerificationForUuid:(NSString*)uuid reply:(void (^)(NSError* error))reply
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self deletePath:[NSString stringWithFormat:@"/users/%@/phones/%@/verification", username, uuid]
          parameters:nil
               reply:^(NSError* error, id content)
    {
        reply ? reply(error) : 0;
    }];
}


// 2E. UPDATE VERIFIED NUMBER
- (void)updatePhoneVerificationForUuid:(NSString*)uuid name:(NSString*)name reply:(void (^)(NSError* error))reply
{
    NSString*     username   = [Settings sharedSettings].webUsername;
    NSDictionary* parameters = @{@"name" : name};

    [self putPath:[NSString stringWithFormat:@"/users/%@/phones/%@", username, uuid]
       parameters:parameters
            reply:^(NSError* error, id content)
    {
        reply(error);
    }];
}


// 2F. CHECK VOICE VERIFICATION CODE
- (void)checkVoiceVerificationCode:(NSString*)code
                           forUuid:(NSString*)uuid
                             reply:(void (^)(NSError* error, BOOL isVerified))reply
{
    NSString*     username   = [Settings sharedSettings].webUsername;
    NSDictionary* parameters = @{@"code" : code};

    [self postPath:[NSString stringWithFormat:@"/users/%@/phones/%@/verification", username, uuid]
          parameters:parameters
               reply:^(NSError* error, id content)
    {
        reply ? reply(error, [content[@"verified"] boolValue]) : 0;
    }];
}


// 3. GET VERIFIED NUMBER LIST
- (void)retrievePhones:(void (^)(NSError* error, NSArray* phones))reply;
{
    [self getPath:[NSString stringWithFormat:@"/users/%@/phones", [Settings sharedSettings].webUsername]
       parameters:nil
            reply:^(NSError* error, id content)
    {
        if (error == nil)
        {
            reply(nil, content);
        }
        else
        {
            reply(error, nil);
        }
    }];
}


// 4. GET VERIFIED NUMBER INFO
- (void)retrievePhoneWithUuid:(NSString*)uuid reply:(void (^)(NSError* error, NSString* e164, NSString* name))reply
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self getPath:[NSString stringWithFormat:@"/users/%@/phones/%@", username, uuid]
       parameters:nil
            reply:^(NSError* error, id content)
    {
        if (error == nil)
        {
            NSString* e164 = content[@"e164"] ? [@"+" stringByAppendingString:content[@"e164"]] : nil;
            reply(nil, e164, content[@"name"]);
        }
        else
        {
            reply(error, nil, nil);
        }
    }];
}


// 5. DELETE VERIFIED NUMBER
- (void)deletePhoneWithUuid:(NSString*)uuid reply:(void (^)(NSError*))reply;
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self deletePath:[NSString stringWithFormat:@"/users/%@/phones/%@", username, uuid]
          parameters:nil
               reply:^(NSError *error, id content)
    {
        reply(error);
    }];
}


// 6A. GET LIST OF ALL AVAILABLE NUMBER COUNTRIES
- (void)retrieveNumberCountries:(void (^)(NSError* error, NSArray* countries))reply
{
    [self getPath:@"/numbers/countries" parameters:nil reply:reply];
}


// 6B. GET NUMBER COUNTRY INFO
- (void)retrieveNumberCountryWithIsoCountryCode:(NSString*)isoCountryCode
                                          reply:(void (^)(NSError* error, NSArray* countryInfo))reply
{
    [self getPath:[NSString stringWithFormat:@"/numbers/countries/%@", isoCountryCode] parameters:nil reply:reply];
}


// 7. GET LIST OF ALL AVAILABLE NUMBER STATES
- (void)retrieveNumberStatesForIsoCountryCode:(NSString*)isoCountryCode
                                        reply:(void (^)(NSError* error, NSArray* states))reply
{
    [self getPath:[NSString stringWithFormat:@"/numbers/countries/%@/states", isoCountryCode]
       parameters:nil
            reply:reply];
}


// 8A. GET LIST OF ALL AVAILABLE NUMBER AREAS (with states)
- (void)retrieveNumberAreasForIsoCountryCode:(NSString*)isoCountryCode
                                   stateCode:(NSString*)stateCode
                              numberTypeMask:(NumberTypeMask)numberTypeMask
                                currencyCode:(NSString*)currencyCode
                                       reply:(void (^)(NSError* error, NSArray* areas))reply
{
    NSDictionary* parameters = @{@"numberType"   : [NumberType stringForNumberTypeMask:numberTypeMask],
                                 @"currencyCode" : currencyCode};

    [self getPath:[NSString stringWithFormat:@"/numbers/countries/%@/states/%@/areas", isoCountryCode, stateCode]
       parameters:parameters
            reply:reply];
}


// 8B. GET LIST OF ALL AVAILABLE NUMBER AREAS (no states)
- (void)retrieveNumberAreasForIsoCountryCode:(NSString*)isoCountryCode
                              numberTypeMask:(NumberTypeMask)numberTypeMask
                                currencyCode:(NSString*)currencyCode
                                       reply:(void (^)(NSError* error, NSArray* areas))reply
{
    NSDictionary* parameters = @{@"numberType"   : [NumberType stringForNumberTypeMask:numberTypeMask],
                                 @"currencyCode" : currencyCode};

    [self getPath:[NSString stringWithFormat:@"/numbers/countries/%@/areas", isoCountryCode]
       parameters:parameters
            reply:reply];
}


// 9. GET PURCHASE INFO DATA
- (void)retrieveNumberAreaInfoForIsoCountryCode:(NSString*)isoCountryCode
                                         areaId:(NSString*)areaId
                                          reply:(void (^)(NSError*        error,
                                                          NSArray*        cities,
                                                          AddressTypeMask addressType,
                                                          BOOL            alwaysRequired,
                                                          NSDictionary*   personRegulations,
                                                          NSDictionary*   companyRegulations))reply
{
    [self getPath:[NSString stringWithFormat:@"/numbers/countries/%@/areas/%@", isoCountryCode, areaId]
       parameters:nil
            reply:^(NSError *error, id content)
    {
        if (error == nil)
        {
            reply(nil,
                  content[@"cities"],
                  [AddressType addressTypeMaskForString:content[@"addressType"]],
                  [content[@"alwaysRequired"] boolValue],
                  content[@"person"],
                  content[@"company"]);
        }
        else
        {
            reply(error, nil, 0, NO, nil, nil);
        }
    }];
}


// 10. CHECK IF PURCHASE INFO IS VALID
- (void)checkPurchaseInfo:(NSDictionary*)info reply:(void (^)(NSError* error, BOOL isValid))reply;
{
    [self postPath:@"/numbers/check"
        parameters:info
             reply:^(NSError *error, id content)
    {
        if (error == nil)
        {
            reply(nil, [content[@"isValid"] boolValue]);
        }
        else
        {
            reply(error, NO);
        }
    }];
}


// 10A. GET LIST OF REGULATION ADDRESSES
- (void)retrieveAddressesForIsoCountryCode:(NSString*)isoCountryCode
                                  areaCode:(NSString*)areaCode
                                numberType:(NumberTypeMask)numberTypeMask
                           isExtranational:(BOOL)isExtranational
                                     reply:(void (^)(NSError* error, NSArray* addresses))reply
{
    NSString*            username   = [Settings sharedSettings].webUsername;
    NSString*            numberType = [NumberType stringForNumberTypeMask:numberTypeMask];
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    
    (isoCountryCode.length > 0) ? parameters[@"isoCountryCode"] = isoCountryCode : 0;
    (areaCode.length       > 0) ? parameters[@"areaCode"]       = areaCode       : 0;
    (numberTypeMask        > 0) ? parameters[@"numberType"]     = numberType     : 0;
    parameters[@"extranational"] = BOOLEAN(isExtranational);
    parameters[@"imageless"]     = BOOLEAN(YES);

    [self getPath:[NSString stringWithFormat:@"/users/%@/addresses", username]
       parameters:parameters
            reply:reply];
}


// 10B. GET REGULATION ADDRESS
- (void)retrieveAddressWithUuid:(NSString*)uuid
                      imageless:(BOOL)imageless
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
{
    NSString*     username   = [Settings sharedSettings].webUsername;
    NSDictionary* parameters = @{@"imageless" : BOOLEAN(imageless)};

    [self getPath:[NSString stringWithFormat:@"/users/%@/addresses/%@", username, uuid]
                                  parameters:parameters
                                       reply:^(NSError *error, id content)
    {
        if (error == nil)
        {
            reply(nil,
                  content[@"name"],
                  content[@"salutation"],
                  content[@"firstName"],
                  content[@"lastName"],
                  content[@"companyName"],
                  content[@"companyDescription"],
                  content[@"street"],
                  content[@"buildingNumber"],
                  content[@"buildingLetter"],
                  content[@"city"],
                  content[@"postcode"],
                  content[@"isoCountryCode"],
                  content[@"areaCode"],
                  content[@"addressProofMd5"],
                  content[@"identityProofMd5"],
                  [Base64 decode:content[@"addressProof"]],
                  [Base64 decode:content[@"identityProof"]],
                  content[@"idType"],
                  content[@"idNumber"],
                  content[@"fiscalIdCode"],
                  content[@"streetCode"],
                  content[@"municipalityCode"],
                  [AddressStatus addressStatusMaskForString:content[@"addressStatus"]],
                  [AddressStatus rejectionReasonsMaskForArray:content[@"rejectionReasons"]]);
        }
        else
        {
            reply(error, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
                  nil, nil, nil, nil, nil, nil, nil, 0, 0);
        }
    }];
}


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
                           nationality:(NSString*)nationality   // Also an ISO-2 country code.
                                idType:(NSString*)idType
                              idNumber:(NSString*)idNumber
                          fiscalIdCode:(NSString*)fiscalIdCode
                            streetCode:(NSString*)streetCode
                      municipalityCode:(NSString*)municipalityCode
                                 reply:(void (^)(NSError*  error,
                                                 NSString* uuid,
                                                 NSString* addressStatus,
                                                 NSArray*  missingFields))reply
{
    NSString*            username   = [Settings sharedSettings].webUsername;
    NSString*            numberType = [NumberType stringForNumberTypeMask:numberTypeMask];
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    
    (name.length               > 0) ? parameters[@"name"]               = name                          : 0;
    (salutation.length         > 0) ? parameters[@"salutation"]         = salutation                    : 0;
    (firstName.length          > 0) ? parameters[@"firstName"]          = firstName                     : 0;
    (lastName.length           > 0) ? parameters[@"lastName"]           = lastName                      : 0;
    (companyName.length        > 0) ? parameters[@"companyName"]        = companyName                   : 0;
    (companyDescription.length > 0) ? parameters[@"companyDescription"] = companyDescription            : 0;
    (street.length             > 0) ? parameters[@"street"]             = street                        : 0;
    (buildingNumber.length     > 0) ? parameters[@"buildingNumber"]     = buildingNumber                : 0;
    (buildingLetter.length     > 0) ? parameters[@"buildingLetter"]     = buildingLetter                : 0;
    (city.length               > 0) ? parameters[@"city"]               = city                          : 0;
    (postcode.length           > 0) ? parameters[@"postcode"]           = postcode                      : 0;
    (isoCountryCode.length     > 0) ? parameters[@"isoCountryCode"]     = isoCountryCode                : 0;
    (areaCode.length           > 0) ? parameters[@"areaCode"]           = areaCode                      : 0;
    (addressProof.length       > 0) ? parameters[@"addressProof"]       = [Base64 encode:addressProof]  : 0;
    (identityProof.length      > 0) ? parameters[@"identityProof"]      = [Base64 encode:identityProof] : 0;
    (nationality.length        > 0) ? parameters[@"nationality"]        = nationality                   : 0;
    (idType.length             > 0) ? parameters[@"idType"]             = idType                        : 0;
    (idNumber.length           > 0) ? parameters[@"idNumber"]           = idNumber                      : 0;
    (fiscalIdCode.length       > 0) ? parameters[@"fiscalIdCode"]       = fiscalIdCode                  : 0;
    (streetCode.length         > 0) ? parameters[@"streetCode"]         = streetCode                    : 0;
    (municipalityCode.length   > 0) ? parameters[@"municipalityCode"]   = municipalityCode              : 0;
                            
    [self postPath:[NSString stringWithFormat:@"/users/%@/addresses?isoCountryCode=%@&numberType=%@",
                                              username, numberIsoCountryCode, numberType]
        parameters:parameters
             reply:^(NSError *error, id content)
     {
         if (error == nil)
         {
             reply(nil, content[@"uuid"], content[@"addressStatus"], content[@"missingFields"]);
         }
         else
         {
             reply(error, nil, nil, nil);
         }
     }];
}


// 10D. DELETE REGULATION ADDRESS
- (void)deleteAddressWithUuid:(NSString*)uuid reply:(void (^)(NSError* error))reply
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self deletePath:[NSString stringWithFormat:@"/users/%@/addresses/%@", username, uuid]
          parameters:nil
               reply:^(NSError *error, id content)
    {
        reply(error);
    }];
}


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
{
    NSString*            username   = [Settings sharedSettings].webUsername;
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];

    (name.length               > 0) ? parameters[@"name"]               = name                          : 0;
    (salutation.length         > 0) ? parameters[@"salutation"]         = salutation                    : 0;
    (firstName.length          > 0) ? parameters[@"firstName"]          = firstName                     : 0;
    (lastName.length           > 0) ? parameters[@"lastName"]           = lastName                      : 0;
    (companyName.length        > 0) ? parameters[@"companyName"]        = companyName                   : 0;
    (companyDescription.length > 0) ? parameters[@"companyDescription"] = companyDescription            : 0;
    (street.length             > 0) ? parameters[@"street"]             = street                        : 0;
    (buildingNumber.length     > 0) ? parameters[@"buildingNumber"]     = buildingNumber                : 0;
    (buildingLetter.length     > 0) ? parameters[@"buildingLetter"]     = buildingLetter                : 0;
    (city.length               > 0) ? parameters[@"city"]               = city                          : 0;
    (postcode.length           > 0) ? parameters[@"postcode"]           = postcode                      : 0;
    (isoCountryCode.length     > 0) ? parameters[@"isoCountryCode"]     = isoCountryCode                : 0;
    (addressProof.length       > 0) ? parameters[@"addressProof"]       = [Base64 encode:addressProof]  : 0;
    (identityProof.length      > 0) ? parameters[@"identityProof"]      = [Base64 encode:identityProof] : 0;
    (idType.length             > 0) ? parameters[@"idType"]             = idType                        : 0;
    (idNumber.length           > 0) ? parameters[@"idNumber"]           = idNumber                      : 0;
    (fiscalIdCode.length       > 0) ? parameters[@"fiscalIdCode"]       = fiscalIdCode                  : 0;
    (streetCode.length         > 0) ? parameters[@"streetCode"]         = streetCode                    : 0;
    (municipalityCode.length   > 0) ? parameters[@"municipalityCode"]   = municipalityCode              : 0;

    [self putPath:[NSString stringWithFormat:@"/users/%@/addresses/%@", username, uuid]
       parameters:parameters
            reply:^(NSError* error, id content)
    {
        if (error == nil)
        {
            reply(error, content[@"addressStatus"]);
        }
        else
        {
            reply(error, nil);
        }
    }];
}


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
                                          float     renewFee))reply
{
    NSString*            username   = [Settings sharedSettings].webUsername;
    NSMutableDictionary* parameters = [@{@"durationMonths" : @(months),
                                         @"name"           : name,
                                         @"isoCountryCode" : isoCountryCode,
                                         @"areaId"         : areaId,
                                         @"autoRenew"      : BOOLEAN(autoRenew)} mutableCopy];
    (addressUuid != nil) ? parameters[@"addressUuid"] = addressUuid : 0;
    // parameters[@"debug"] = @NO;

    [self postPath:[NSString stringWithFormat:@"/users/%@/numbers", username]
        parameters:parameters
             reply:^(NSError* error, id content)
    {
        if (error == nil)
        {
            reply(nil,
                  content[@"uuid"],
                  content[@"e164"] ? [@"+" stringByAppendingString:content[@"e164"]] : nil,
                  [Common dateWithString:content[@"purchaseDateTime"]],
                  [Common dateWithString:content[@"expiryDateTime"]],
                  [content[@"monthFee"] floatValue],
                  [content[@"renewFee"] floatValue]);
        }
        else
        {
            reply(error, nil, nil, nil, nil, 0.0f, 0.0f);
        }
    }];
}


// 11B. UPDATE NUMBER ATTRIBUTES
- (void)updateNumberWithUuid:(NSString*)uuid
                        name:(NSString*)name
                   autoRenew:(BOOL)autoRenew
             destinationUuid:(NSString*)destinationUuid
                 addressUuid:(NSString*)addressUuid
                       reply:(void (^)(NSError*  error,
                                       NSString* e164,
                                       NSDate*   purchaseDate,
                                       NSDate*   expiryDate,
                                       float     monthFee,
                                       float     renewFee))reply
{
    NSString*            username   = [Settings sharedSettings].webUsername;
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];

    parameters[@"autoRenew"]                                      = BOOLEAN(autoRenew);
    (name.length            > 0) ? parameters[@"name"]            = name            : 0;
    (destinationUuid     != nil) ? parameters[@"destinationUuid"] = destinationUuid : 0;
    (addressUuid.length     > 0) ? parameters[@"addressUuid"]     = addressUuid     : 0;

    [self postPath:[NSString stringWithFormat:@"/users/%@/numbers/%@", username, uuid]
        parameters:parameters
             reply:^(NSError* error, id content)
    {
        if (error == nil)
        {
            reply(nil,
                  content[@"e164"] ? [@"+" stringByAppendingString:content[@"e164"]] : nil,
                  [Common dateWithString:content[@"purchaseDateTime"]],
                  [Common dateWithString:content[@"expiryDateTime"]],
                  [content[@"monthFee"] floatValue],
                  [content[@"renewFee"] floatValue]);
        }
        else
        {
            reply(error, nil, nil, nil, 0.0f, 0.0f);
        }
    }];
}


// 11C. EXTEND NUMBER
- (void)extendNumberWithUuid:(NSString*)uuid
                   forMonths:(NSUInteger)months
                       reply:(void (^)(NSError* error,
                                       float    monthFee,
                                       float    renewFee,
                                       NSDate*  expiryDate))reply
{
    NSString*     username   = [Settings sharedSettings].webUsername;
    NSDictionary* parameters = @{@"durationMonths" : @(months)};

    [self postPath:[NSString stringWithFormat:@"/users/%@/numbers/%@", username, uuid]
        parameters:parameters
             reply:^(NSError* error, id content)
    {
        reply(error,
              [content[@"monthFee"] floatValue],
              [content[@"renewFee"] floatValue],
              [Common dateWithString:content[@"expiryDateTime"]]);
    }];
}


// 11D. DELETE PENDING NUMBER
- (void)deleteNumberWithUuid:(NSString*)uuid
                       reply:(void (^)(NSError* error))reply
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self deletePath:[NSString stringWithFormat:@"/users/%@/numbers/%@", username, uuid]
          parameters:nil
               reply:^(NSError* error, id content)
    {
        reply(error);
    }];
}

// 12. GET LIST OF NUMBERS
- (void)retrieveNumbers:(void (^)(NSError* error, NSArray* numbers))reply
{
    [self getPath:[NSString stringWithFormat:@"/users/%@/numbers", [Settings sharedSettings].webUsername]
       parameters:nil
            reply:^(NSError* error, id content)
    {
        if (error == nil)
        {
            reply(nil, content);
        }
        else
        {
            reply(error, nil);
        }
    }];
}


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
                                         float           renewFee))reply
{
    NSString*     username     = [Settings sharedSettings].webUsername;
    NSString*     currencyCode = [Settings sharedSettings].storeCurrencyCode;
    NSString*     countryCode  = [Settings sharedSettings].storeCountryCode;
    NSDictionary* parameters   = @{@"currencyCode" : currencyCode, @"countryCode" : countryCode};

    [self getPath:[NSString stringWithFormat:@"/users/%@/numbers/%@", username, uuid]
       parameters:parameters
            reply:^(NSError *error, id content)
    {
        if (error == nil)
        {
            reply(nil,
                  content[@"e164"] ? [@"+" stringByAppendingString:content[@"e164"]] : nil,
                  content[@"name"],
                  content[@"numberType"],
                  content[@"areaCode"],
                  content[@"areaName"],
                  content[@"areaId"],
                  content[@"stateCode"],
                  content[@"stateName"],
                  content[@"isoCountryCode"],
                  content[@"addressUuid"],
                  [AddressType addressTypeMaskForString:content[@"addressType"]],
                  [Common dateWithString:content[@"purchaseDateTime"]],
                  [Common dateWithString:content[@"expiryDateTime"]],
                  [content[@"autoRenew"] boolValue],
                  content[@"destinationUuid"],
                  [content[@"fixedRate"] floatValue],
                  [content[@"fixedSetup"] floatValue],
                  [content[@"mobileRate"] floatValue],
                  [content[@"mobileSetup"] floatValue],
                  [content[@"payphoneRate"] floatValue],
                  [content[@"payphoneSetup"] floatValue],
                  [content[@"monthFee"] floatValue],
                  [content[@"renewFee"] floatValue]);
        }
        else
        {
            reply(error, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0, nil, nil, NO, nil,
                  0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f);
        }
    }];
}


// 14. BUY CREDIT
- (void)purchaseCreditForReceipt:(NSString*)receipt reply:(void (^)(NSError* error, float credit))reply
{
    NSString*     username     = [Settings sharedSettings].webUsername;
    NSString*     currencyCode = [Settings sharedSettings].storeCurrencyCode;
    NSString*     countryCode  = [Settings sharedSettings].storeCountryCode;
    NSDictionary* parameters   = @{@"receipt" : receipt};
    
    [self putPath:[NSString stringWithFormat:@"/users/%@/credit?currencyCode=%@&countryCode=%@",
                   username, currencyCode, countryCode]
       parameters:parameters
            reply:^(NSError* error, id content)
    {
        if (error == nil)
        {
            reply(nil, [content[@"credit"] floatValue]);
        }
        else
        {
            reply(error, 0.0f);
        }
    }];
}


// 15. GET CURRENT CALLING CREDIT
- (void)retrieveCreditWithReply:(void (^)(NSError* error, float credit))reply
{
    NSString*     username     = [Settings sharedSettings].webUsername;
    NSString*     currencyCode = [Settings sharedSettings].storeCurrencyCode;
    NSString*     countyCode   = [Settings sharedSettings].storeCountryCode;
    NSDictionary* parameters   = @{@"currencyCode" : currencyCode, @"countryCode" : countyCode};

    [self getPath:[NSString stringWithFormat:@"/users/%@/credit", username]
       parameters:parameters
            reply:^(NSError* error, id content)
    {
        if (error == nil)
        {
            reply(nil, [content[@"credit"] floatValue]);
        }
        else
        {
            reply(error, 0.0f);
        }
    }];
}


// 16. GET CALL RATE (PER MINUTE)
- (void)retrieveCallRateForE164:(NSString*)e164 reply:(void (^)(NSError* error, float ratePerMinute))reply
{
    NSString* e164x        = [e164 substringFromIndex:1];
    NSString* currencyCode = [Settings sharedSettings].storeCurrencyCode;
    NSString* countryCode  = [Settings sharedSettings].storeCountryCode;
    
    // Don't call `handleAccount` and get data without needing account.

    [self.webInterface getPath:[NSString stringWithFormat:@"/rate/%@?currencyCode=%@&countryCode=%@",
                                                          e164x, currencyCode, countryCode]
                    parameters:nil
                         reply:^(NSError *error, id content)
    {
        if (error == nil)
        {
            reply(error, [content[@"rate"] floatValue]);
        }
        else
        {
            reply(error, 0.0f);
        }
    }];
}


// 17. GET CDRS
- (void)retrieveCallRecordsFromDate:(NSDate*)date
                            inbound:(BOOL)inbound
                           outbound:(BOOL)outbound
                       verification:(BOOL)verification
                              reply:(void (^)(NSError* error, NSArray* records))reply
{
    NSString* username       = [Settings sharedSettings].webUsername;
    NSString* currencyCode   = [Settings sharedSettings].storeCurrencyCode;
    NSString* countryCode    = [Settings sharedSettings].storeCountryCode;
    NSString* fromDateString = [Common stringWithDate:date];

    fromDateString = [fromDateString stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    fromDateString = [fromDateString stringByReplacingOccurrencesOfString:@":" withString:@"%3A"];

    [self getPath:[NSString stringWithFormat:@"/users/%@/cdrs?inbound=%@&outbound=%@&verification=%@&fromDateTime=%@&currencyCode=%@&countryCode=%@&hideRetryMs=12000",
                   username,
                   inbound      ? @"true" : @"false",
                   outbound     ? @"true" : @"false",
                   verification ? @"true" : @"false",
                   fromDateString,
                   currencyCode,
                   countryCode]
       parameters:nil
            reply:^(NSError* error, id content)
    {
        if (error == nil)
        {
            reply(nil, content);
        }
        else
        {
            reply(error, nil);
        }
    }];
}


// 18. GET VOICEMAIL STATUS
// ...


// 19A. CREATE DESTINATION
- (void)createDestinationWithName:(NSString*)name
                   action:(NSDictionary*)action
                    reply:(void (^)(NSError* error, NSString* uuid))reply
{
    NSString*     username   = [Settings sharedSettings].webUsername;
    NSDictionary* parameters = @{@"name"   : name,
                                 @"action" : [self stripE164InAction:action]};

    [self postPath:[NSString stringWithFormat:@"/users/%@/destinations", username]
        parameters:parameters
             reply:^(NSError* error, id content)
    {
        if (error == nil)
        {
            reply(nil, content[@"uuid"]);
        }
        else
        {
            reply(error, nil);
        }
    }];
}


// 19B. CREATE OR UPDATE DESTINATION
- (void)updateDestinationForUuid:(NSString*)uuid
                    name:(NSString*)name
                  action:(NSDictionary*)action
                   reply:(void (^)(NSError* error))reply
{
    NSString*     username   = [Settings sharedSettings].webUsername;
    NSDictionary* parameters = @{@"name"   : name,
                                 @"action" : [self stripE164InAction:action]};

    [self putPath:[NSString stringWithFormat:@"/users/%@/destinations/%@", username, uuid]
       parameters:parameters
            reply:^(NSError* error, id content)
    {
        reply(error);
    }];
}


// 20. DELETE DESTINATION
- (void)deleteDestinationForUuid:(NSString*)uuid reply:(void (^)(NSError* error))reply
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self deletePath:[NSString stringWithFormat:@"/users/%@/destinations/%@", username, uuid]
          parameters:nil
               reply:^(NSError* error, id content)
    {
        reply(error);
    }];
}


// 21. GET LIST OF DESTINATIONS
- (void)retrieveDestinations:(void (^)(NSError* error, NSArray* destinations))reply
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self getPath:[NSString stringWithFormat:@"/users/%@/destinations", username]
       parameters:nil
            reply:reply];
}


// 22. DOWNLOAD DESTINATION
- (void)retrieveDestinationForUuid:(NSString*)uuid
                             reply:(void (^)(NSError* error, NSString* name, NSDictionary* action))reply
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self getPath:[NSString stringWithFormat:@"/users/%@/destinations/%@", username, uuid]
       parameters:nil
            reply:^(NSError* error, id content)
    {
        if (error == nil)
        {
            NSDictionary* action = content[@"action"];
            action = [self restoreE164InAction:action];
            reply(nil, content[@"name"], action);
        }
        else
        {
            reply(error, nil, nil);
        }
    }];
}


// 25. UPDATE AUDIO
- (void)updateAudioForUuid:(NSString*)uuid
                      data:(NSData*)data
                      name:(NSString*)name
                     reply:(void (^)(NSError* error))reply
{
    NSString*            username   = [Settings sharedSettings].webUsername;
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];

    (data        != nil) ? parameters[@"data"]     = [Base64 encode:data] : 0;
    (name.length  > 0)   ? parameters[@"name"]     = name                 : 0;

    [self putPath:[NSString stringWithFormat:@"/users/%@/audios/%@", username, uuid]
       parameters:parameters
            reply:^(NSError* error, id content)
    {
        reply(error);
    }];
}


// 26. DOWNLOAD AUDIO
- (void)retrieveAudioForUuid:(NSString*)uuid reply:(void (^)(NSError* error, NSString* name, NSData* data))reply
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self getPath:[NSString stringWithFormat:@"/users/%@/audios/%@", username, uuid]
       parameters:nil
            reply:^(NSError* error, id content)
    {
        if (error == nil)
        {
            reply(nil,
                  content[@"name"],
                  [Base64 decode:content[@"data"]]);
        }
        else
        {
            reply(error, nil, nil);
        }
    }];
}


// 27. DELETE AUDIO
- (void)deleteAudioForUuid:(NSString*)uuid reply:(void (^)(NSError* error))reply
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self deletePath:[NSString stringWithFormat:@"/users/%@/audios/%@", username, uuid]
          parameters:nil
               reply:^(NSError *error, id content)
    {
        reply(error);
    }];
}


// 28. GET LIST OF AUDIO UUID'S
- (void)retrieveAudios:(void (^)(NSError* error, NSArray* audios))reply
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self getPath:[NSString stringWithFormat:@"/users/%@/audios", username]
       parameters:nil
            reply:reply];
}


// 29. CREATE AUDIO
- (void)createAudioWithData:(NSData*)data name:(NSString*)name reply:(void (^)(NSError* error, NSString* uuid))reply
{
    NSString*     username   = [Settings sharedSettings].webUsername;
    NSDictionary* parameters = @{@"data"     : [Base64 encode:data],
                                 @"name"     : name};

    [self postPath:[NSString stringWithFormat:@"/users/%@/audios", username]
        parameters:parameters
             reply:^(NSError* error, id content)
    {
        if (error == nil)
        {
            reply(nil, content[@"uuid"]);
        }
        else
        {
            reply(error, nil);
        }
    }];
}


// 32. INITIATE CALLBACK
- (void)initiateCallbackForCallbackE164:(NSString*)callbackE164
                           callthruE164:(NSString*)callthruE164
                           identityE164:(NSString*)identityE164
                                privacy:(BOOL)privacy
                                  reply:(void (^)(NSError* error, NSString* uuid))reply;
{
    NSString*     username   = [Settings sharedSettings].webUsername;
    NSDictionary* parameters = @{@"callbackE164" : [callbackE164 substringFromIndex:1],
                                 @"callthruE164" : [callthruE164 substringFromIndex:1],
                                 @"identityE164" : [identityE164 substringFromIndex:1],
                                 @"privacy"      : BOOLEAN(privacy)};
    
    [self postPath:[NSString stringWithFormat:@"/users/%@/callback", username]
        parameters:parameters
             reply:^(NSError* error, id content)
    {
        if (error == nil)
        {
            reply(nil, content[@"uuid"]);
        }
        else
        {
            reply(error, nil);
        }
    }];
}


// 33. STOP CALLBACK
- (void)stopCallbackForUuid:(NSString*)uuid reply:(void (^)(NSError* error))reply
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self deletePath:[NSString stringWithFormat:@"/users/%@/callback/%@", username, uuid]
          parameters:nil
               reply:^(NSError* error, id content)
    {
        reply ? reply(error) : 0;
    }];
}


// 34. GET CALLBACK STATE
- (void)retrieveCallbackStateForUuid:(NSString*)uuid
                               reply:(void (^)(NSError*  error,
                                               CallState state,
                                               CallLeg   leg,
                                               int       callbackDuration,
                                               int       callthruDuration,
                                               float     callbackCost,
                                               float     callthruCost))reply
{    
    NSString* username     = [Settings sharedSettings].webUsername;
    NSString* currencyCode = [Settings sharedSettings].storeCurrencyCode;
    NSString* countryCode  = [Settings sharedSettings].storeCountryCode;

    [self getPath:[NSString stringWithFormat:@"/users/%@/callback/%@?currencyCode=%@&countryCode=%@",
                                             username, uuid, currencyCode, countryCode]
       parameters:nil
            reply:^(NSError* error, id content)
    {
        if (error == nil)
        {
            NSString* stateString = content[@"state"];
            CallState state;
            CallLeg   leg;

            if ([stateString isEqualToString:@"CALLBACK_RINGING"])
            {
                state = CallStateCalling;
                leg   = CallLegCallback;
            }
            else if ([stateString isEqualToString:@"CALLBACK_EARLY"])
            {
                state = CallStateRinging;
                leg   = CallLegCallback;
            }
            else if ([stateString isEqualToString:@"CALLBACK_ANSWERED"])
            {
                state = CallStateConnected;
                leg   = CallLegCallback;
            }
            else if ([stateString isEqualToString:@"CALLBACK_HANGUP"])
            {
                state = CallStateEnded;
                leg   = CallLegCallback;
            }
            else if ([stateString isEqualToString:@"CALLTHRU_RINGING"])
            {
                state = CallStateCalling;
                leg   = CallLegCallthru;
            }
            else if ([stateString isEqualToString:@"CALLTHRU_EARLY"])
            {
                state = CallStateRinging;
                leg   = CallLegCallthru;
            }
            else if ([stateString isEqualToString:@"CALLTHRU_ANSWERED"])
            {
                state = CallStateConnected;
                leg   = CallLegCallthru;
            }
            else if ([stateString isEqualToString:@"CALLTHRU_HANGUP"])
            {
                state = CallStateEnded;
                leg   = CallLegCallthru;
            }
            else
            {
                // This when the server sends an undefined state.
                state = CallStateNone;
                leg   = CallLegNone;
                NBLog(@"Received undefined callback state: %@", stateString);
            }

            reply(nil,
                  state,
                  leg,
                  [content[@"callbackDuration"] intValue],
                  [content[@"callthruDuration"] intValue],
                  [content[@"callbackCost"]     floatValue],
                  [content[@"callthruCost"]     floatValue]);
        }
        else
        {
            NBLog(@"%@", error);
            reply(error, CallStateFailed, CallLegNone, 0, 0, 0.0f, 0.0f);
        }
    }];
}


// 40A. GET ALL MESSAGES
- (void)retrieveMessages:(void (^)(NSError* error, NSArray* messages))reply
{
    NSString* username       = [Settings sharedSettings].webUsername;
    
    [self getPath:[NSString stringWithFormat:@"/users/%@/messages", username]
       parameters:nil
            reply:^(NSError* error, NSArray* content)
    {
        if (error == nil)
        {
            reply(nil, content);
        }
        else
        {
            reply(error, nil);
        }
    }];
}


// 40A. GET ALL MESSAGES
- (void)retrieveMessagesFromDate:(NSDate*)date reply:(void (^)(NSError*, NSArray*))reply
{
    NSString* username       = [Settings sharedSettings].webUsername;
    NSString* fromDateString = [Common stringWithDate:date];
    
    fromDateString = [fromDateString stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    fromDateString = [fromDateString stringByReplacingOccurrencesOfString:@":" withString:@"%3A"];
    
    [self getPath:[NSString stringWithFormat:@"/users/%@/messages/updates/%@", username, fromDateString]
       parameters:nil
            reply:^(NSError* error, NSArray* content)
    {
        if (error == nil)
        {
            reply(nil, content);
        }
        else
        {
            reply(error, nil);
        }
    }];
}


// Send message - /users/{user_id}/messages - Body: {from_number, to_number, msg}
- (void)sendMessage:(MessageData*)message reply:(void(^)(NSError* error, NSString* uuid))reply
{
    // @TODO: Change this, so the data is correct and in the same format as the server.
    // @TODO: Is this the right place to remove the "+"
    NSString*     username   = [Settings sharedSettings].webUsername;
    NSDictionary* parameters = @{@"from_number" : [message.numberE164 stringByReplacingOccurrencesOfString:@"+" withString:@""],
                                 @"to_number"   : [message.externE164 stringByReplacingOccurrencesOfString:@"+" withString:@""],
                                 @"msg"         : message.text};
    
    [self postPath:[NSString stringWithFormat:@"/users/%@/messages", username]
        parameters:parameters
             reply:^(NSError* error, id content)
     {
         if (error == nil)
         {
             reply(nil, content[@"uuid"]);
         }
         else
         {
             reply(error, nil);
         }
     }];
}


#pragma mark - Public Utility

// 0A.
- (void)cancelAllRetrieveCallRates
{
    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodGet
                                                    path:@"/rates/calls"];
}


// 0B.
- (void)cancelAllRetrieveNumberRates
{
    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodGet
                                                    path:@"/rates/numbers"];
}


// 1.
- (void)cancelAllRetrieveWebAccount
{
    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodPost
                                                    path:@"/users"];
}


// 2A.
- (void)cancelAllRetrievePhoneVerificationCode
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodPost
                                                    path:[NSString stringWithFormat:@"/users/%@/phones",
                                                          username]];
}


// 2B.
- (void)cancelAllRequestPhoneVerificationCallForUuid:(NSString*)uuid
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodPut
                                                    path:[NSString stringWithFormat:@"/users/%@/phones/%@/verification",
                                                          username, uuid]];
}


// 2C.
- (void)cancelAllRetrievePhoneVerificationStatusForUuid:(NSString*)uuid
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodGet
                                                    path:[NSString stringWithFormat:@"/users/%@/phones/%@/verification",
                                                          username, uuid]];
}


// 2D.
- (void)cancelAllStopPhoneVerificationForUuid:(NSString*)uuid
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodDelete
                                                    path:[NSString stringWithFormat:@"/users/%@/phones/%@/verification",
                                                          username, uuid]];
}


// 2E.
- (void)cancelAllUpdatePhoneVerificationForUuid:(NSString*)uuid
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodPut
                                                    path:[NSString stringWithFormat:@"/users/%@/phones/%@",
                                                          username, uuid]];
}


// 2F.
- (void)cancelAllCheckVoiceVerificationCodeForUuid:(NSString*)uuid;
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodPost
                                                  path:[NSString stringWithFormat:@"/users/%@/phones/%@/verification",
                                                        username, uuid]];
}


// 3.
- (void)cancelAllRetrievePhonesList
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodGet
                                                    path:[NSString stringWithFormat:@"/users/%@/phones",
                                                          username]];
}


// 4.
- (void)cancelAllRetrievePhoneWithUuid:(NSString*)uuid
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodGet
                                                    path:[NSString stringWithFormat:@"/users/%@/phones/%@",
                                                          username, uuid]];
}


// 5.
- (void)cancelAllDeletePhoneWithUuid:(NSString*)uuid
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodDelete
                                                    path:[NSString stringWithFormat:@"/users/%@/phones/%@",
                                                          username, uuid]];
}


// 6A.
- (void)cancelAllRetrieveNumberCountries
{
    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodGet
                                                    path:@"/numbers/countries"];
}


// 6B.
- (void)cancelAllRetrieveNumberCountryWithIsoCountryCode:(NSString*)isoCountryCode
{
    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodGet
                                                    path:[NSString stringWithFormat:@"/numbers/countries/%@", isoCountryCode]];
}


// 7.
- (void)cancelAllRetrieveNumberStatesForIsoCountryCode:(NSString*)isoCountryCode
{
    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodGet
                                                    path:[NSString stringWithFormat:@"/numbers/countries/%@/states",
                                                          isoCountryCode]];
}


// 8A.
- (void)cancelAllRetrieveNumberAreasForIsoCountryCode:(NSString*)isoCountryCode stateCode:(NSString*)stateCode
{
    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodGet
                                                    path:[NSString stringWithFormat:@"/numbers/countries/%@/states/%@/areas",
                                                          isoCountryCode, stateCode]];
}


// 8B.
- (void)cancelAllRetrieveNumberAreasForIsoCountryCode:(NSString*)isoCountryCode
{
    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodGet
                                                    path:[NSString stringWithFormat:@"/numbers/countries/%@/areas",
                                                          isoCountryCode]];
}


// 9.
- (void)cancelAllRetrieveAreaInfoForIsoCountryCode:(NSString*)isoCountryCode areaId:(NSString*)areaId
{
    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodGet
                                                    path:[NSString stringWithFormat:@"/numbers/countries/%@/areas/%@",
                                                          isoCountryCode, areaId]];
}


// 10.
- (void)cancelAllCheckPurchaseInfo
{
    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodPost
                                                    path:@"/numbers/check"];
}


// 10A.
- (void)cancelAllRetrieveAddresses
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodGet
                                                    path:[NSString stringWithFormat:@"/users/%@/addresses", username]];
}


// 10B.
- (void)cancelAllRetrieveAddressWithUuid:(NSString*)uuid
{
    NSString* username = [Settings sharedSettings].webUsername;
    
    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodGet
                                                    path:[NSString stringWithFormat:@"/users/%@/addresses/%@",
                                                          username, uuid]];
}


// 10C.
- (void)cancelAllCreateAddress
{
    NSString* username = [Settings sharedSettings].webUsername;
    
    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodPost
                                                    path:[NSString stringWithFormat:@"/users/%@/addresses", username]];
}


// 10D.
- (void)cancelAllDeleteAddressWithUuid:(NSString*)uuid
{
    NSString* username = [Settings sharedSettings].webUsername;
    
    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodDelete
                                                    path:[NSString stringWithFormat:@"/users/%@/addresses/%@",
                                                          username, uuid]];
}


// 11A.
- (void)cancelAllPurchaseNumber
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodPost
                                                    path:[NSString stringWithFormat:@"/users/%@/numbers",
                                                          username]];
}


// 11B.
- (void)cancelAllUpdateNumberWithUuid:(NSString*)uuid;
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodPost
                                                    path:[NSString stringWithFormat:@"/users/%@/numbers/%@",
                                                          username, uuid]];
}


// 11C.
- (void)cancelAllExtendNumberWithUuid:(NSString*)uuid;
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodPut
                                                    path:[NSString stringWithFormat:@"/users/%@/numbers/%@",
                                                          username, uuid]];
}


// 12.
- (void)cancelAllRetrieveNumbersList
{
    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodGet
                                                    path:[NSString stringWithFormat:@"/users/%@/numbers",
                                                          [Settings sharedSettings].webUsername]];
}


// 13.
- (void)cancelAllRetrieveNumberWithUuid:(NSString*)uuid
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodGet
                                                    path:[NSString stringWithFormat:@"/users/%@/numbers/%@",
                                                          username, uuid]];
}


// 14.
- (void)cancelAllPurchaseCredit
{
    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodPost
                                                    path:[NSString stringWithFormat:@"/users/%@/credit",
                                                          [Settings sharedSettings].webUsername]];
}


// 15.
- (void)cancelAllRetrieveCredit
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodGet
                                                    path:[NSString stringWithFormat:@"/users/%@/credit",
                                                          username]];
}


// 16.
- (void)cancelAllRetrieveCallRateForE164:(NSString*)e164
{
    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodGet
                                                    path:[NSString stringWithFormat:@"/rate/%@",
                                                          [e164 substringFromIndex:1]]];
}


// 19.
- (void)cancelAllCreateDestinationForUuid:(NSString*)uuid
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodPut
                                                    path:[NSString stringWithFormat:@"/users/%@/destinations/%@",
                                                          username, uuid]];
}


// 20.
- (void)cancelAllDeleteDestinationForUuid:(NSString*)uuid
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodDelete
                                                    path:[NSString stringWithFormat:@"/users/%@/destinations/%@",
                                                          username, uuid]];
}


// 21.
- (void)cancelAllRetrieveDestinationsList
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodGet
                                                    path:[NSString stringWithFormat:@"/users/%@/destinations",
                                                          username]];
}


// 22.
- (void)cancelAllRetrieveDestinationForUuid:(NSString*)uuid
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodGet
                                                    path:[NSString stringWithFormat:@"/users/%@/destinations/%@",
                                                          username, uuid]];
}


// 25.
- (void)cancellAllUpdateAudioForUuid:(NSString*)uuid
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodPut
                                                    path:[NSString stringWithFormat:@"/users/%@/audios/%@",
                                                          username, uuid]];
}


// 26.
- (void)cancelAllRetrieveAudioForUuid:(NSString*)uuid
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodGet
                                                    path:[NSString stringWithFormat:@"/users/%@/audios/%@",
                                                          username, uuid]];
}


// 27.
- (void)cancelAllDeleteAudioForUuid:(NSString*)uuid
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodDelete
                                                    path:[NSString stringWithFormat:@"/users/%@/audios/%@",
                                                          username, uuid]];}


// 28.
- (void)cancelAllRetrieveAudioList
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodGet
                                                    path:[NSString stringWithFormat:@"/users/%@/audios",
                                                          username]];
}


// 29.
- (void)cancelAllCreateAudio
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodPost
                                                    path:[NSString stringWithFormat:@"/users/%@/audios",
                                                          username]];
}


// 32.
- (void)cancelAllInitiateCallback
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodPost
                                                    path:[NSString stringWithFormat:@"/users/%@/callback",
                                                          username]];
}


// 33.
- (void)cancelAllStopCallbackForUuid:(NSString*)uuid
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodDelete
                                                    path:[NSString stringWithFormat:@"/users/%@/callback/%@",
                                                          username, uuid]];
}


// 34.
- (void)cancelAllRetrieveCallbackStateForUuid:(NSString*)uuid
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpRequestsWithMethod:RequestMethodGet
                                                    path:[NSString stringWithFormat:@"/users/%@/callback/%@",
                                                          username, uuid]];
}

@end
