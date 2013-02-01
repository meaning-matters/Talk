//
//  Common.h
//  Talk
//
//  Created by Cornelis van der Bent on 30/09/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"

#define CFReleaseSafe(x)    { if ((x) != NULL) CFRelease(x); }

@interface Common : NSObject

+ (NSString*)documentFilePath:(NSString*)fileName;

+ (NSData*)dataForResource:(NSString*)resourse ofType:(NSString*)type;

+ (NSString*)bundleVersion;

+ (NSString*)bundleName;

+ (NSData*)jsonDataWithObject:(id)object;

+ (NSString*)jsonStringWithObject:(id)object;

+ (id)objectWithJsonData:(NSData*)data;

+ (id)objectWithJsonString:(NSString*)string;

+ (NSString*)deviceModel;

+ (BOOL)deviceHasReceiver;

+ (void)postNotificationName:(NSString*)name object:(id)object;

+ (void)postNotificationName:(NSString *)name userInfo:(NSDictionary*)userInfo object:(id)object;

+ (void)setCornerRadius:(CGFloat)radius ofView:(UIView*)view;

+ (void)setX:(CGFloat)x ofView:(UIView*)view;

+ (void)setY:(CGFloat)y ofView:(UIView*)view;

+ (void)setWidth:(CGFloat)width ofView:(UIView*)view;

+ (void)setHeight:(CGFloat)height ofView:(UIView*)view;

+ (UIFont*)phoneFontOfSize:(CGFloat)size;

+ (NSString*)stringWithOsStatus:(OSStatus)status;

+ (BOOL)checkRemoteNotifications;

@end
