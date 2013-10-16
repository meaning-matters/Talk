//
//  Common.h
//  Talk
//
//  Created by Cornelis van der Bent on 30/09/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"


// http://stackoverflow.com/questions/3172794/scope-bar-for-uitableview-like-app-store
#define UndocumentedSearchScopeBarSegmentedControlStyle 7

#define CFReleaseSafe(x)                                { if ((x) != NULL) CFRelease(x); }


@interface Common : NSObject

+ (NSURL*)documentsDirectoryUrl;

+ (NSURL*)documentUrl:(NSString*)name;

+ (NSURL*)audioDirectoryUrl;

+ (NSURL*)audioUrl:(NSString*)name;

+ (NSData*)dataForResource:(NSString*)resourse ofType:(NSString*)type;

+ (NSString*)bundleVersion;

+ (NSString*)bundleName;

+ (NSString*)appStoreUrlString;

+ (NSData*)jsonDataWithObject:(id)object;

+ (NSString*)jsonStringWithObject:(id)object;

+ (id)objectWithJsonData:(NSData*)data;

+ (id)objectWithJsonString:(NSString*)string;

+ (id)mutableObjectWithJsonData:(NSData*)data;

+ (id)mutableObjectWithJsonString:(NSString*)string;

+ (NSError*)errorWithCode:(NSInteger)code description:(NSString*)description;

+ (BOOL)deviceHasReceiver;

+ (NSString*)deviceModel;

+ (void)setCornerRadius:(CGFloat)radius ofView:(UIView*)view;

+ (void)setBorderWidth:(CGFloat)width ofView:(UIView*)view;

+ (void)setBorderColor:(UIColor*)color ofView:(UIView*)view;

+ (void)setX:(CGFloat)x ofView:(UIView*)view;

+ (void)setY:(CGFloat)y ofView:(UIView*)view;

+ (void)setWidth:(CGFloat)width ofView:(UIView*)view;

+ (void)setHeight:(CGFloat)height ofView:(UIView*)view;

+ (UIFont*)phoneFontOfSize:(CGFloat)size;

+ (NSString*)stringWithOsStatus:(OSStatus)status;

+ (BOOL)checkRemoteNotifications;

+ (BOOL)checkSendingEmail;

+ (BOOL)checkSendingTextMessage;

// Works only for non-emergency numbers.
+ (BOOL)checkCountryOfPhoneNumber:(PhoneNumber*)phoneNumber
                       completion:(void (^)(BOOL cancelled, PhoneNumber* phoneNumber))completion;

+ (void)enableNetworkActivityIndicator:(BOOL)enable;

+ (void)redirectStderrToFile;

+ (unsigned)bitsSetCount:(unsigned long)value;

+ (unsigned long)nthBitSet:(unsigned)n inValue:(unsigned long)value;    // With n == 0 return first bit set.

+ (unsigned)nOfBit:(unsigned long)bit inValue:(unsigned long)value;     // Converts table section mask to section.

+ (unsigned long)bitIndex:(unsigned long)value;                         // Converts table section mask to index.

+ (NSString*)capitalizedString:(NSString*)string;

+ (void)showProvisioningViewController;

+ (void)dispatchAfterInterval:(NSTimeInterval)interval onMain:(void (^)(void))block;

+ (void)addCountryImageToCell:(UITableViewCell*)cell isoCountryCode:(NSString*)isoCountryCode;

@end
