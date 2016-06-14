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

- (NSDate*)dateWithString:(NSString*)string // Used to convert Number date to NSDate.
{
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-M-d H:m:s"];

    return [formatter dateFromString:string];
}


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
    AnalysticsTrace(@"API_0A");

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
    AnalysticsTrace(@"API_0B");

    NSString* currencyCode = [Settings sharedSettings].storeCurrencyCode;
    NSString* countryCode  = [Settings sharedSettings].storeCountryCode;
    
    // Don't call `handleAccount` and get data without needing account.

    [self.webInterface getPath:[NSString stringWithFormat:@"/rates/numbers?currencyCode=%@&countryCode=%@",
                                                          currencyCode, countryCode]
                    parameters:nil
                         reply:reply];
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
                                            NSString* webPassword))reply;
{
    AnalysticsTrace(@"API_1A");

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
        reply(error, content[@"webUsername"], content[@"webPassword"]);
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
                                           NSString* webPassword))reply
{
    AnalysticsTrace(@"API_1B");

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
        reply(error, content[@"webUsername"], content[@"webPassword"]);
    }];
}


// 2A. GET PHONE VERIFICATION CODE
- (void)retrievePhoneVerificationCodeForE164:(NSString*)e164
                                       reply:(void (^)(NSError* error, NSString* code))reply
{
    AnalysticsTrace(@"API_2A");

    NSString*     username   = [Settings sharedSettings].webUsername;
    NSDictionary* parameters = @{@"e164" : [e164 substringFromIndex:1]};

    [self postPath:[NSString stringWithFormat:@"/users/%@/phones", username]
        parameters:parameters
             reply:^(NSError* error, id content)
    {
        if (error == nil)
        {
            reply(nil, content[@"code"]);
        }
        else
        {
            reply(error, nil);
        }
    }];
}


// 2B. REQUEST PHONE VERIFICATION CALL
- (void)requestPhoneVerificationCallForE164:(NSString*)e164
                                      reply:(void (^)(NSError* error))reply
{
    AnalysticsTrace(@"API_2B");

    NSString* username = [Settings sharedSettings].webUsername;
    NSString* e164x    = [e164 substringFromIndex:1];

    [self putPath:[NSString stringWithFormat:@"/users/%@/phones/%@/verification", username, e164x]
       parameters:nil
            reply:^(NSError* error, id content)
    {
        reply(error);
    }];
}


// 2C. CHECK PHONE VERIFICATION STATUS
- (void)retrievePhoneVerificationStatusForE164:(NSString*)e164
                                         reply:(void (^)(NSError* error, BOOL calling, BOOL verified))reply
{
    AnalysticsTrace(@"API_2C");

    NSString* username = [Settings sharedSettings].webUsername;
    NSString* e164x    = [e164 substringFromIndex:1];

    [self getPath:[NSString stringWithFormat:@"/users/%@/phones/%@/verification", username, e164x]
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
- (void)stopPhoneVerificationForE164:(NSString*)e164 reply:(void (^)(NSError* error))reply
{
    AnalysticsTrace(@"API_2D");

    NSString* username = [Settings sharedSettings].webUsername;
    NSString* e164x    = [e164 substringFromIndex:1];

    [self deletePath:[NSString stringWithFormat:@"/users/%@/phones/%@/verification", username, e164x]
          parameters:nil
               reply:^(NSError* error, id content)
    {
        reply ? reply(error) : 0;
    }];
}


// 2E. UPDATE VERIFIED NUMBER
- (void)updatePhoneVerificationForE164:(NSString*)e164 name:(NSString*)name reply:(void (^)(NSError* error))reply
{
    AnalysticsTrace(@"API_2E");
    
    NSString*     username   = [Settings sharedSettings].webUsername;
    NSString*     e164x      = [e164 substringFromIndex:1];
    NSDictionary* parameters = @{@"name" : name};

    [self putPath:[NSString stringWithFormat:@"/users/%@/phones/%@", username, e164x]
       parameters:parameters
            reply:^(NSError* error, id content)
    {
        reply(error);
    }];
}


// 3. GET VERIFIED NUMBER LIST
- (void)retrievePhonesList:(void (^)(NSError* error, NSArray* e164s))reply;
{
    AnalysticsTrace(@"API_3");

    [self getPath:[NSString stringWithFormat:@"/users/%@/phones", [Settings sharedSettings].webUsername]
       parameters:nil
            reply:^(NSError* error, id content)
    {
        if (error == nil)
        {
            NSMutableArray* e164s = [NSMutableArray array];
            for (NSString* e164x in content)
            {
                [e164s addObject:[@"+" stringByAppendingString:e164x]];
            }
            
            reply(nil, e164s);
        }
        else
        {
            reply(error, nil);
        }
    }];
}


// 4. GET VERIFIED NUMBER INFO
- (void)retrievePhoneWithE164:(NSString*)e164
                       reply:(void (^)(NSError* error, NSString* name))reply;
{
    AnalysticsTrace(@"API_3");

    NSString* username = [Settings sharedSettings].webUsername;
    NSString* e164x    = [e164 substringFromIndex:1];

    [self getPath:[NSString stringWithFormat:@"/users/%@/phones/%@", username, e164x]
       parameters:nil
            reply:^(NSError* error, id content)
    {
        if (error == nil)
        {
            reply(nil, content[@"name"]);
        }
        else
        {
            reply(error, nil);
        }
    }];
}


// 5. DELETE VERIFIED NUMBER
- (void)deleteVerifiedE164:(NSString*)e164
                     reply:(void (^)(NSError*))reply;
{
    AnalysticsTrace(@"API_5");
    
    NSString* username = [Settings sharedSettings].webUsername;
    NSString* e164x    = [e164 substringFromIndex:1];

    [self deletePath:[NSString stringWithFormat:@"/users/%@/phones/%@", username, e164x]
          parameters:nil
               reply:^(NSError *error, id content)
    {
        reply(error);
    }];
}


// 6. GET LIST OF ALL AVAILABLE NUMBER COUNTRIES
- (void)retrieveNumberCountries:(void (^)(NSError* error, NSArray* countries))reply
{
    [self getPath:@"/numbers/countries" parameters:nil reply:reply];
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
                                       areaCode:(NSString*)areaCode
                                          reply:(void (^)(NSError* error, NSArray* areaInfo))reply
{
    [self getPath:[NSString stringWithFormat:@"/numbers/countries/%@/areas/%@", isoCountryCode, areaCode]
       parameters:nil
            reply:reply];
}


// 10. CHECK IF PURCHASE INFO IS VALID
- (void)checkPurchaseInfo:(NSDictionary*)info
                    reply:(void (^)(NSError* error, BOOL isValid))reply;
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
                                     reply:(void (^)(NSError* error, NSArray* addressIds))reply
{
    NSString*            username   = [Settings sharedSettings].webUsername;
    NSString*            numberType = [NumberType stringForNumberTypeMask:numberTypeMask];
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    
    (isoCountryCode.length > 0) ? parameters[@"isoCountryCode"] = isoCountryCode : 0;
    (areaCode.length       > 0) ? parameters[@"areaCode"]       = areaCode       : 0;
    (numberTypeMask        > 0) ? parameters[@"numberType"]     = numberType     : 0;

    [self getPath:[NSString stringWithFormat:@"/users/%@/addresses", username]
       parameters:parameters
            reply:reply];
}


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
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self getPath:[NSString stringWithFormat:@"/users/%@/addresses/%@", username, addressId]
                                  parameters:nil
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
                  [content[@"hasProof"] boolValue],
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
            reply(error, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, NO, nil, nil, nil, nil, nil, 0, 0);
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
                            proofImage:(NSData*)proofImage
                                idType:(NSString*)idType
                              idNumber:(NSString*)idNumber
                          fiscalIdCode:(NSString*)fiscalIdCode
                            streetCode:(NSString*)streetCode
                      municipalityCode:(NSString*)municipalityCode
                                 reply:(void (^)(NSError*  error,
                                                 NSString* addressId,
                                                 NSString* addressStatus,
                                                 NSArray*  missingFields))reply
{
    NSString*            username   = [Settings sharedSettings].webUsername;
    NSString*            numberType = [NumberType stringForNumberTypeMask:numberTypeMask];
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    
    (name.length               > 0) ? parameters[@"name"]               = name                       : 0;
    (salutation.length         > 0) ? parameters[@"salutation"]         = salutation                 : 0;
    (firstName.length          > 0) ? parameters[@"firstName"]          = firstName                  : 0;
    (lastName.length           > 0) ? parameters[@"lastName"]           = lastName                   : 0;
    (companyName.length        > 0) ? parameters[@"companyName"]        = companyName                : 0;
    (companyDescription.length > 0) ? parameters[@"companyDescription"] = companyDescription         : 0;
    (street.length             > 0) ? parameters[@"street"]             = street                     : 0;
    (buildingNumber.length     > 0) ? parameters[@"buildingNumber"]     = buildingNumber             : 0;
    (buildingLetter.length     > 0) ? parameters[@"buildingLetter"]     = buildingLetter             : 0;
    (city.length               > 0) ? parameters[@"city"]               = city                       : 0;
    (postcode.length           > 0) ? parameters[@"postcode"]           = postcode                   : 0;
    (isoCountryCode.length     > 0) ? parameters[@"isoCountryCode"]     = isoCountryCode             : 0;
    (proofImage.length         > 0) ? parameters[@"proofImage"]         = [Base64 encode:proofImage] : 0;
    (idType.length             > 0) ? parameters[@"idType"]             = idType                     : 0;
    (idNumber.length           > 0) ? parameters[@"idNumber"]           = idNumber                   : 0;
    (fiscalIdCode.length       > 0) ? parameters[@"fiscalIdCode"]       = fiscalIdCode               : 0;
    (streetCode.length         > 0) ? parameters[@"streetCode"]         = streetCode                 : 0;
    (municipalityCode.length   > 0) ? parameters[@"municipalityCode"]   = municipalityCode           : 0;
                            
    [self postPath:[NSString stringWithFormat:@"/users/%@/addresses?isoCountryCode=%@&numberType=%@",
                                              username, numberIsoCountryCode, numberType]
        parameters:parameters
             reply:^(NSError *error, id content)
     {
         if (error == nil)
         {
             reply(nil, content[@"addressId"], content[@"addressStatus"], content[@"missingFields"]);
         }
         else
         {
             reply(error, nil, nil, nil);
         }
     }];
}


// 10D. DELETE REGULATION ADDRESS
- (void)deleteAddressWithId:(NSString*)addressId
                      reply:(void (^)(NSError* error))reply
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self deletePath:[NSString stringWithFormat:@"/users/%@/addresses/%@", username, addressId]
          parameters:nil
               reply:^(NSError *error, id content)
    {
        reply(error);
    }];
}


// 10E. GET ADDRESS PROOF IMAGE
- (void)retrieveImageForAddressId:(NSString*)addressId
                            reply:(void (^)(NSError* error, NSData* proofImage))reply
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self getPath:[NSString stringWithFormat:@"/users/%@/addresses/%@/image", username, addressId]
       parameters:nil
            reply:^(NSError *error, id content)
    {
        if (error == nil)
        {
            reply(nil, [Base64 decode:content[@"proofImage"]]);
        }
        else
        {
            reply(error, nil);
        }
    }];
}


// 10F. UPDATE ADDRESS PROOF IMAGE
- (void)updateImageForAddressId:(NSString*)addressId
                          reply:(void (^)(NSError* error))reply
{
    NSString* username = [Settings sharedSettings].webUsername;
    
    [self putPath:[NSString stringWithFormat:@"/users/%@/addresses/%@/image", username, addressId]
       parameters:nil
            reply:^(NSError *error, id content)
    {
        reply(error);
    }];
}


// 10G. UPDATE ADDRESS' NAME
- (void)updateAddressWithId:(NSString*)addressId withName:(NSString*)name reply:(void (^)(NSError* error))reply
{
    NSString*     username   = [Settings sharedSettings].webUsername;
    NSDictionary* parameters = @{@"name" : name};
    
    [self putPath:[NSString stringWithFormat:@"/users/%@/addresses/%@", username, addressId]
       parameters:parameters
            reply:^(NSError* error, id content)
    {
        reply(error);
    }];
}


// 11A. PURCHASE NUMBER
- (void)purchaseNumberForMonths:(NSUInteger)months
                           name:(NSString*)name
                 isoCountryCode:(NSString*)isoCountryCode
                         areaId:(NSString*)areaId
                      addressId:(NSString*)addressId
                      autoRenew:(BOOL)autoRenew
                          reply:(void (^)(NSError* error, NSString* e164, NSDate* purchaseDate, NSDate* renewalDate))reply
{
    NSString*            username   = [Settings sharedSettings].webUsername;
    NSMutableDictionary* parameters = [@{@"durationMonths" : @(months),
                                         @"name"           : name,
                                         @"isoCountryCode" : isoCountryCode,
                                         @"areaId"         : areaId,
                                         @"autoRenew"      : @(autoRenew)} mutableCopy];
    (addressId != nil) ? parameters[@"addressId"] = addressId : 0;
    // parameters[@"debug"] = @(false);

    [self postPath:[NSString stringWithFormat:@"/users/%@/numbers", username]
        parameters:parameters
             reply:^(NSError* error, id content)
    {
        if (error == nil)
        {
            reply(nil,
                  [@"+" stringByAppendingString:content[@"e164"]],
                  [NSDate date],
                  [NSDate date]);
//                  [self dateWithString:content[@"purchaseDateTime"]],
  //                [self dateWithString:content[@"renewalDateTime"]]);
        }
        else
        {
            reply(error, nil, nil, nil);
        }
    }];
}


// 11B. UPDATE NUMBER'S NAME
- (void)updateNumberE164:(NSString*)e164
                withName:(NSString*)name
               autoRenew:(BOOL)autoRenew
                   reply:(void (^)(NSError* error))reply;
{
    NSString*     username   = [Settings sharedSettings].webUsername;
    NSString*     number     = [e164 substringFromIndex:1];
    NSDictionary* parameters = @{@"name"      : name,
                                 @"autoRenew" : @(autoRenew)};

    [self postPath:[NSString stringWithFormat:@"/users/%@/numbers/%@", username, number]
        parameters:parameters
             reply:^(NSError* error, id content)
    {
        reply(error);
    }];
}


// 11C. EXTEND NUMBER
- (void)extendNumberE164:(NSString*)e164 forMonths:(NSUInteger)months reply:(void (^)(NSError* error))reply
{
    NSString*     username   = [Settings sharedSettings].webUsername;
    NSString*     number     = [e164 substringFromIndex:1];
    NSDictionary* parameters = @{@"durationMonths" : @(months)};

    [self postPath:[NSString stringWithFormat:@"/users/%@/numbers/%@", username, number]
        parameters:parameters
             reply:^(NSError* error, id content)
    {
        reply(error);
    }];
}


// 12. GET LIST OF NUMBERS
- (void)retrieveNumbersList:(void (^)(NSError* error, NSArray* e164s))reply
{
    [self getPath:[NSString stringWithFormat:@"/users/%@/numbers", [Settings sharedSettings].webUsername]
       parameters:nil
            reply:^(NSError* error, id content)
    {
        if (error == nil)
        {
            NSMutableArray* e164s = [NSMutableArray array];
            for (NSString* e164x in content)
            {
                [e164s addObject:[@"+" stringByAppendingString:e164x]];
            }

            reply(nil, e164s);
        }
        else
        {
            reply(error, nil);
        }
    }];
}


// 13. GET NUMBER INFO
- (void)retrieveNumberWithE164:(NSString*)e164
                         reply:(void (^)(NSError*  error,
                                         NSString* name,
                                         NSString* numberType,
                                         NSString* areaCode,
                                         NSString* areaName,
                                         NSString* stateCode,
                                         NSString* stateName,
                                         NSString* isoCountryCode,
                                         NSDate*   purchaseDate,
                                         NSDate*   renewalDate,
                                         BOOL      autoRenew,
                                         float     monthFee,
                                         NSString* addressId))reply
{
    NSString*     username     = [Settings sharedSettings].webUsername;
    NSString*     number       = [e164 substringFromIndex:1];
    NSString*     currencyCode = [Settings sharedSettings].storeCurrencyCode;
    NSString*     countryCode  = [Settings sharedSettings].storeCountryCode;
    NSDictionary* parameters   = @{@"currencyCode" : currencyCode, @"countryCode" : countryCode};

    [self getPath:[NSString stringWithFormat:@"/users/%@/numbers/%@", username, number]
       parameters:parameters
            reply:^(NSError *error, id content)
    {
        if (error == nil)
        {
            reply(nil,
                  content[@"name"],
                  content[@"numberType"],
                  content[@"areaCode"],
                  content[@"areaName"],
                  content[@"stateCode"],
                  content[@"stateName"],
                  content[@"isoCountryCode"],
                  [self dateWithString:content[@"purchaseDateTime"]],
                  [self dateWithString:content[@"renewalDateTime"]],
                  [content[@"autoRenew"] boolValue],
                  [content[@"monthFee"] floatValue],
                  content[@"addressId"]);
        }
        else
        {
            reply(error, nil, nil, nil, nil, nil, nil, nil, nil, nil, NO, 0.0f, nil);
        }
    }];
}


// 13B. GET NUMBER PROOF IMAGE
- (void)retrieveNumberImageE164:(NSString*)e164
{
    //###
    //    [Base64 decode:content[@"info"][@"proofImage"]],
    //[content[@"info"][@"proofAccepted"] boolValue]);

}


// 14. BUY CREDIT
- (void)purchaseCreditForReceipt:(NSString*)receipt
                           reply:(void (^)(NSError* error, float credit))reply
{
    AnalysticsTrace(@"API_14");
    
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
    AnalysticsTrace(@"API_15");
    
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
- (void)retrieveCallRateForE164:(NSString*)e164
                          reply:(void (^)(NSError* error, float ratePerMinute))reply
{
    AnalysticsTrace(@"API_16");
    
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
// ...


// 18. GET VOICEMAIL STATUS
// ...


// 19A. CREATE DESTINATION
- (void)createDestinationWithName:(NSString*)name
                   action:(NSDictionary*)action
                    reply:(void (^)(NSError* error, NSString* uuid))reply
{
    AnalysticsTrace(@"API_19A");

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
    AnalysticsTrace(@"API_19B");

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
- (void)deleteDestinationForUuid:(NSString*)uuid
                   reply:(void (^)(NSError* error))reply
{
    AnalysticsTrace(@"API_20");

    NSString* username = [Settings sharedSettings].webUsername;

    [self deletePath:[NSString stringWithFormat:@"/users/%@/destinations/%@", username, uuid]
          parameters:nil
               reply:^(NSError* error, id content)
    {
        reply(error);
    }];
}


// 21. GET LIST OF DESTINATIONS
- (void)retrieveDestinationsList:(void (^)(NSError* error, NSArray* uuids))reply
{
    AnalysticsTrace(@"API_21");

    NSString* username = [Settings sharedSettings].webUsername;

    [self getPath:[NSString stringWithFormat:@"/users/%@/destinations", username]
       parameters:nil
            reply:reply];
}


// 22. DOWNLOAD DESTINATION
- (void)retrieveDestinationForUuid:(NSString*)uuid
                     reply:(void (^)(NSError* error, NSString* name, NSDictionary* action))reply
{
    AnalysticsTrace(@"API_22");

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


// 23. SET/CLEAR DESTINATION FOR A NUMBER
- (void)setDestinationOfE164:(NSString*)e164
                uuid:(NSString*)uuid
               reply:(void (^)(NSError* error))reply
{
    AnalysticsTrace(@"API_23");

    NSString*     username   = [Settings sharedSettings].webUsername;
    NSString*     number     = [e164 substringFromIndex:1];
    NSDictionary* parameters = @{@"uuid" : uuid};

    [self putPath:[NSString stringWithFormat:@"/users/%@/numbers/%@/destination", username, number]
       parameters:parameters
            reply:^(NSError* error, id content)
    {
        reply(error);
    }];
}


// 24. RETRIEVE DESTINATION FOR A NUMBER
- (void)retrieveDestinationOfE164:(NSString*)e164
                    reply:(void (^)(NSError* error, NSString* uuid))reply
{
    AnalysticsTrace(@"API_24");

    NSString* username = [Settings sharedSettings].webUsername;
    NSString* number   = [e164 substringFromIndex:1];

    [self getPath:[NSString stringWithFormat:@"/users/%@/numbers/%@/destination", username, number]
       parameters:nil
            reply:^(NSError* error, id content)
    {
        if (error == nil)
        {
            reply(nil, ([content[@"uuid"] length] > 0) ? content[@"uuid"] : nil);
        }
        else
        {
            reply(error, nil);
        }
    }];
}


// 25. UPDATE AUDIO
- (void)updateAudioForUuid:(NSString*)uuid
                      data:(NSData*)data
                      name:(NSString*)name
                     reply:(void (^)(NSError* error))reply
{
    AnalysticsTrace(@"API_25");

    NSString*            username   = [Settings sharedSettings].webUsername;
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];

    (data        != nil) ? parameters[@"data"]     = [Base64 encode:data] : 0;
    (name.length  > 0)   ? parameters[@"name"]     = name                 : 0;

    [self putPath:[NSString stringWithFormat:@"/users/%@/audio/%@", username, uuid]
       parameters:parameters
            reply:^(NSError* error, id content)
    {
        reply(error);
    }];
}


// 26. DOWNLOAD AUDIO
- (void)retrieveAudioForUuid:(NSString*)uuid
                       reply:(void (^)(NSError*  error,
                                       NSString* name,
                                       NSData*   data))reply
{
    AnalysticsTrace(@"API_26");

    NSString* username = [Settings sharedSettings].webUsername;

    [self getPath:[NSString stringWithFormat:@"/users/%@/audio/%@", username, uuid]
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
- (void)deleteAudioForUuid:(NSString*)uuid
                     reply:(void (^)(NSError*  error))reply
{
    AnalysticsTrace(@"API_27");

    NSString* username = [Settings sharedSettings].webUsername;

    [self deletePath:[NSString stringWithFormat:@"/users/%@/audio/%@", username, uuid]
          parameters:nil
               reply:^(NSError *error, id content)
    {
        reply(error);
    }];
}


// 28. GET LIST OF AUDIO UUID'S
- (void)retrieveAudioList:(void (^)(NSError* error, NSArray* uuids))reply
{
    AnalysticsTrace(@"API_28");

    NSString* username = [Settings sharedSettings].webUsername;

    [self getPath:[NSString stringWithFormat:@"/users/%@/audio", username]
       parameters:nil
            reply:reply];
}


// 29. CREATE AUDIO
- (void)createAudioWithData:(NSData*)data
                       name:(NSString*)name
                      reply:(void (^)(NSError* error, NSString* uuid))reply
{
    AnalysticsTrace(@"API_29");

    NSString*     username   = [Settings sharedSettings].webUsername;
    NSDictionary* parameters = @{@"data"     : [Base64 encode:data],
                                 @"name"     : name};

    [self postPath:[NSString stringWithFormat:@"/users/%@/audio", username]
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
    AnalysticsTrace(@"API_32");
    
    NSString*     username   = [Settings sharedSettings].webUsername;
    NSDictionary* parameters = @{@"callbackE164" : [callbackE164 substringFromIndex:1],
                                 @"callthruE164" : [callthruE164 substringFromIndex:1],
                                 @"identityE164" : [identityE164 substringFromIndex:1],
                                 @"privacy"      : privacy ? @"true" : @"false"};
    
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
- (void)stopCallbackForUuid:(NSString*)uuid
                      reply:(void (^)(NSError* error))reply
{
    AnalysticsTrace(@"API_33");
    
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
    AnalysticsTrace(@"API_34");
    
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

            NBLog(@"Callback: %@", content);

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
                  [content[@"callbackCost"] floatValue],
                  [content[@"callthruCost"] floatValue]);
        }
        else
        {
            NBLog(@"%@", error);
            reply(error, CallStateFailed, CallLegNone, 0, 0, 0.0f, 0.0f);
        }
    }];
}


#pragma mark - Public Utility

// 0A.
- (void)cancelAllRetrieveCallRates
{
    [self.webInterface cancelAllHttpOperationsWithMethod:@"GET"
                                                    path:@"/rates/calls"];
}


// 0B.
- (void)cancelAllRetrieveNumberRates
{
    [self.webInterface cancelAllHttpOperationsWithMethod:@"GET"
                                                    path:@"/rates/numbers"];
}


// 1.
- (void)cancelAllRetrieveWebAccount
{
    [self.webInterface cancelAllHttpOperationsWithMethod:@"POST"
                                                    path:@"/users"];
}


// 2A.
- (void)cancelAllRetrievePhoneVerificationCode
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpOperationsWithMethod:@"POST"
                                                    path:[NSString stringWithFormat:@"/users/%@/verification",
                                                          username]];
}


// 2B.
- (void)cancelAllRequestPhoneVerificationCall
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpOperationsWithMethod:@"PUT"
                                                    path:[NSString stringWithFormat:@"/users/%@/verification",
                                                          username]];
}


// 2C.
- (void)cancelAllRetrievePhoneVerificationStatus
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpOperationsWithMethod:@"GET"
                                                    path:[NSString stringWithFormat:@"/users/%@/verification",
                                                          username]];
}


// 2D.
- (void)cancelAllStopPhoneVerification
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpOperationsWithMethod:@"DELETE"
                                                    path:[NSString stringWithFormat:@"/users/%@/verification",
                                                          username]];
}


// 2E.
- (void)cancelAllUpdatePhoneVerificationForE164:(NSString*)e164
{
    NSString* username = [Settings sharedSettings].webUsername;
    NSString* number   = [e164 substringFromIndex:1];

    [self.webInterface cancelAllHttpOperationsWithMethod:@"POST"
                                                    path:[NSString stringWithFormat:@"/users/%@/verification/numbers/%@",
                                                          username, number]];
}


// 3.
- (void)cancelAllRetrievePhonesList
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpOperationsWithMethod:@"GET"
                                                    path:[NSString stringWithFormat:@"/users/%@/verification/numbers",
                                                          username]];
}


// 4.
- (void)cancelAllRetrievePhoneWithE164:(NSString*)e164
{
    NSString* username = [Settings sharedSettings].webUsername;
    NSString* number   = [e164 substringFromIndex:1];

    [self.webInterface cancelAllHttpOperationsWithMethod:@"GET"
                                                    path:[NSString stringWithFormat:@"/users/%@/verification/numbers/%@",
                                                          username, number]];
}


// 5.
- (void)cancelAllDeleteVerifiedE164:(NSString*)e164
{
    NSString* username = [Settings sharedSettings].webUsername;
    NSString* number   = [e164 substringFromIndex:1];

    [self.webInterface cancelAllHttpOperationsWithMethod:@"DELETE"
                                                    path:[NSString stringWithFormat:@"/users/%@/verification/numbers/%@",
                                                          username, number]];
}


// 6.
- (void)cancelAllRetrieveNumberCountries
{
    [self.webInterface cancelAllHttpOperationsWithMethod:@"GET"
                                                    path:@"/numbers/countries"];
}


// 7.
- (void)cancelAllRetrieveNumberStatesForIsoCountryCode:(NSString*)isoCountryCode
{
    [self.webInterface cancelAllHttpOperationsWithMethod:@"GET"
                                                    path:[NSString stringWithFormat:@"/numbers/countries/%@/states",
                                                          isoCountryCode]];
}


// 8A.
- (void)cancelAllRetrieveNumberAreasForIsoCountryCode:(NSString*)isoCountryCode stateCode:(NSString*)stateCode
{
    [self.webInterface cancelAllHttpOperationsWithMethod:@"GET"
                                                    path:[NSString stringWithFormat:@"/numbers/countries/%@/states/%@/areas",
                                                          isoCountryCode, stateCode]];
}


// 8B.
- (void)cancelAllRetrieveNumberAreasForIsoCountryCode:(NSString*)isoCountryCode
{
    [self.webInterface cancelAllHttpOperationsWithMethod:@"GET"
                                                    path:[NSString stringWithFormat:@"/numbers/countries/%@/areas",
                                                          isoCountryCode]];
}


// 9.
- (void)cancelAllRetrieveAreaInfoForIsoCountryCode:(NSString*)isoCountryCode areaCode:(NSString*)areaCode
{
    [self.webInterface cancelAllHttpOperationsWithMethod:@"GET"
                                                    path:[NSString stringWithFormat:@"/numbers/countries/%@/areas/%@",
                                                          isoCountryCode, areaCode]];
}


// 10.
- (void)cancelAllCheckPurchaseInfo
{
    [self.webInterface cancelAllHttpOperationsWithMethod:@"POST"
                                                    path:@"/numbers/check"];
}


// 10A.
- (void)cancelAllRetrieveAddresses
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpOperationsWithMethod:@"GET"
                                                    path:[NSString stringWithFormat:@"/users/%@/addresses", username]];
}


// 10B.
- (void)cancelAllRetrieveAddressWithId:(NSString*)addressId
{
    NSString* username = [Settings sharedSettings].webUsername;
    
    [self.webInterface cancelAllHttpOperationsWithMethod:@"GET"
                                                    path:[NSString stringWithFormat:@"/users/%@/addresses/%@",
                                                          username, addressId]];
}


// 10C.
- (void)cancelAllCreateAddress
{
    NSString* username = [Settings sharedSettings].webUsername;
    
    [self.webInterface cancelAllHttpOperationsWithMethod:@"POST"
                                                    path:[NSString stringWithFormat:@"/users/%@/addresses", username]];
}


// 10D.
- (void)cancelAllDeleteAddressWithId:(NSString*)addressId
{
    NSString* username = [Settings sharedSettings].webUsername;
    
    [self.webInterface cancelAllHttpOperationsWithMethod:@"DELETE"
                                                    path:[NSString stringWithFormat:@"/users/%@/addresses/%@",
                                                          username, addressId]];
}


// 10E.
- (void)cancelAllRetrieveImageForAddressId:(NSString*)addressId
{
    NSString* username = [Settings sharedSettings].webUsername;
    
    [self.webInterface cancelAllHttpOperationsWithMethod:@"GET"
                                                    path:[NSString stringWithFormat:@"/users/%@/addresses/%@/image",
                                                          username, addressId]];
}


// 10F.
- (void)cancelAllUpdateImageForAddressId:(NSString*)addressId
{
    NSString* username = [Settings sharedSettings].webUsername;
    
    [self.webInterface cancelAllHttpOperationsWithMethod:@"PUT"
                                                    path:[NSString stringWithFormat:@"/users/%@/addresses/%@/image",
                                                          username, addressId]];
}


// 11A.
- (void)cancelAllPurchaseNumber
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpOperationsWithMethod:@"POST"
                                                    path:[NSString stringWithFormat:@"/users/%@/numbers",
                                                          username]];
}


// 11B.
- (void)cancelAllUpdateNumberE164:(NSString*)e164;
{
    NSString* username = [Settings sharedSettings].webUsername;
    NSString* number   = [e164 substringFromIndex:1];

    [self.webInterface cancelAllHttpOperationsWithMethod:@"POST"
                                                    path:[NSString stringWithFormat:@"/users/%@/numbers/%@",
                                                          username, number]];
}


// 11C.
- (void)cancelAllExtendNumberE164:(NSString*)e164;
{
    NSString* username = [Settings sharedSettings].webUsername;
    NSString* number   = [e164 substringFromIndex:1];

    [self.webInterface cancelAllHttpOperationsWithMethod:@"PUT"
                                                    path:[NSString stringWithFormat:@"/users/%@/numbers/%@",
                                                          username, number]];
}


// 12.
- (void)cancelAllRetrieveNumbersList
{
    [self.webInterface cancelAllHttpOperationsWithMethod:@"GET"
                                                    path:[NSString stringWithFormat:@"/users/%@/numbers",
                                                          [Settings sharedSettings].webUsername]];
}


// 13.
- (void)cancelAllRetrieveNumberWithE164:(NSString*)e164
{
    NSString* username = [Settings sharedSettings].webUsername;
    NSString* number   = [e164 substringFromIndex:1];

    [self.webInterface cancelAllHttpOperationsWithMethod:@"GET"
                                                    path:[NSString stringWithFormat:@"/users/%@/numbers/%@",
                                                          username, number]];
}


// 14.
- (void)cancelAllPurchaseCredit
{
    [self.webInterface cancelAllHttpOperationsWithMethod:@"POST"
                                                    path:[NSString stringWithFormat:@"/users/%@/credit",
                                                          [Settings sharedSettings].webUsername]];
}


// 15.
- (void)cancelAllRetrieveCredit
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpOperationsWithMethod:@"GET"
                                                    path:[NSString stringWithFormat:@"/users/%@/credit",
                                                          username]];
}


// 16.
- (void)cancelAllRetrieveCallRateForE164:(NSString*)e164
{
    [self.webInterface cancelAllHttpOperationsWithMethod:@"GET"
                                                    path:[NSString stringWithFormat:@"/rate/%@",
                                                          [e164 substringFromIndex:1]]];
}


// 19.
- (void)cancelAllCreateDestinationForUuid:(NSString*)uuid
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpOperationsWithMethod:@"PUT"
                                                    path:[NSString stringWithFormat:@"/users/%@/destinations/%@",
                                                          username, uuid]];
}


// 20.
- (void)cancelAllDeleteDestinationForUuid:(NSString*)uuid
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpOperationsWithMethod:@"DELETE"
                                                    path:[NSString stringWithFormat:@"/users/%@/destinations/%@",
                                                          username, uuid]];
}


// 21.
- (void)cancelAllRetrieveDestinationsList
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpOperationsWithMethod:@"GET"
                                                    path:[NSString stringWithFormat:@"/users/%@/destinations",
                                                          username]];
}


// 22.
- (void)cancelAllRetrieveDestinationForUuid:(NSString*)uuid
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpOperationsWithMethod:@"GET"
                                                    path:[NSString stringWithFormat:@"/users/%@/destinations/%@",
                                                          username, uuid]];
}


// 23.
- (void)cancelAllSetDestinationOfE164:(NSString*)e164
{
    NSString* username = [Settings sharedSettings].webUsername;
    NSString* number   = [e164 substringFromIndex:1];

    [self.webInterface cancelAllHttpOperationsWithMethod:@"PUT"
                                                    path:[NSString stringWithFormat:@"/users/%@/numbers/%@/destination",
                                                          username, number]];
}


// 25.
- (void)cancellAllUpdateAudioForUuid:(NSString*)uuid
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpOperationsWithMethod:@"PUT"
                                                    path:[NSString stringWithFormat:@"/users/%@/audio/%@",
                                                          username, uuid]];
}


// 26.
- (void)cancelAllRetrieveAudioForUuid:(NSString*)uuid
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpOperationsWithMethod:@"GET"
                                                    path:[NSString stringWithFormat:@"/users/%@/audio/%@",
                                                          username, uuid]];
}


// 27.
- (void)cancelAllDeleteAudioForUuid:(NSString*)uuid
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpOperationsWithMethod:@"DELETE"
                                                    path:[NSString stringWithFormat:@"/users/%@/audio/%@",
                                                          username, uuid]];}


// 28.
- (void)cancelAllRetrieveAudioList
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpOperationsWithMethod:@"GET"
                                                    path:[NSString stringWithFormat:@"/users/%@/audio",
                                                          username]];
}


// 29.
- (void)cancelAllCreateAudio
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpOperationsWithMethod:@"POST"
                                                    path:[NSString stringWithFormat:@"/users/%@/audio",
                                                          username]];
}


// 32.
- (void)cancelAllInitiateCallback
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpOperationsWithMethod:@"POST"
                                                    path:[NSString stringWithFormat:@"/users/%@/callback",
                                                          username]];
}


// 33.
- (void)cancelAllStopCallbackForUuid:(NSString*)uuid
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpOperationsWithMethod:@"DELETE"
                                                    path:[NSString stringWithFormat:@"/users/%@/callback/%@",
                                                          username, uuid]];
}


// 34.
- (void)cancelAllRetrieveCallbackStateForUuid:(NSString*)uuid
{
    NSString* username = [Settings sharedSettings].webUsername;

    [self.webInterface cancelAllHttpOperationsWithMethod:@"GET"
                                                    path:[NSString stringWithFormat:@"/users/%@/callback/%@",
                                                          username, uuid]];
}

@end
