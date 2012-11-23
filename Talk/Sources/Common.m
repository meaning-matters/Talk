//
//  Common.m
//  Talk
//
//  Created by Cornelis van der Bent on 30/09/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "Common.h"

@implementation Common

+ (NSString*)documentFilePath:(NSString*)fileName
{
    NSArray*    paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString*   documentsDirectory = [paths objectAtIndex:0];
    
    return [documentsDirectory stringByAppendingPathComponent:fileName];
}


+ (NSData*)dataForResource:(NSString*)resourse ofType:(NSString*)type
{
    NSString*   path = [[NSBundle mainBundle] pathForResource:resourse ofType:type];
    NSData*     data = [NSData dataWithContentsOfFile:path];
    
    return data;
}


+ (NSString*)bundleVersion
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
}


+ (NSString*)bundleName
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleNameKey];
}


+ (NSData*)jsonDataWithObject:(id)object
{
    NSError*                error = nil;
    NSData*                 data;
    NSJSONWritingOptions    options;
    
#ifdef  DEBUG
    options = NSJSONWritingPrettyPrinted;
#else
    options = 0;
#endif
    
    data = [NSJSONSerialization dataWithJSONObject:object options:options error:&error];
    
    if (error != nil)
    {
        //### Replace.
        NSLog(@"Error serializing to JSON data: %@.", [error localizedDescription]);
        
        return nil;
    }
    else
    {
        return data;
    }
}


+ (NSString*)jsonStringWithObject:(id)object
{
    NSData*     data;
    NSString*   string;
    
    data   = [Common jsonDataWithObject:object];
    string = [NSString stringWithUTF8String:[data bytes]];
    
    return string;
}


+ (id)objectWithJsonData:(NSData*)data
{
    NSError*    error = nil;
    id          object;
    
    object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    
    if (error != nil)
    {
        //### Replace.
        NSLog(@"Error serializing from JSON data: %@.", [error localizedDescription]);
        
        return nil;
    }
    else
    {
        return object;
    }
}


+ (id)objectWithJsonString:(NSString*)string
{
    id          object;
    NSData*     data;
    
    data   = [string dataUsingEncoding:NSUTF8StringEncoding];
    object = [Common objectWithJsonData:data];
    
    return object;
}


+ (void)postNotificationName:(NSString*)name object:(id)object
{
    dispatch_async(dispatch_get_main_queue(), ^
                   {
                       [[NSNotificationCenter defaultCenter] postNotificationName:name
                                                                           object:object];
                   });
}


+ (void)postNotificationName:(NSString *)name userInfo:(NSDictionary*)userInfo object:(id)object
{
    dispatch_async(dispatch_get_main_queue(), ^
                   {
                       [[NSNotificationCenter defaultCenter] postNotificationName:name
                                                                           object:object
                                                                         userInfo:userInfo];
                   });
}


+ (void)setCornerRadius:(CGFloat)radius ofView:(UIView*)view
{
    view.layer.cornerRadius = radius;
    view.layer.masksToBounds = YES;
}


+ (void)setY:(CGFloat)y ofView:(UIView*)view
{
    CGRect  frame;

    frame = view.frame;
    frame.origin.y = y;
    view.frame = frame;
}


+ (void)setHeight:(CGFloat)height ofView:(UIView*)view
{
    CGRect  frame;

    frame = view.frame;
    frame.size.height = height;
    view.frame = frame;
}


+ (UIFont*)phoneFontOfSize:(CGFloat)size
{
    // Returns hidden iOS font with nice * # +.
    // List of fonts: http://www.prepressure.com/fonts/basics/ios-4-fonts
    return [UIFont fontWithName:@".PhonepadTwo" size:size];
}


+ (AppDelegate*)appDelegate
{
    return (AppDelegate*)[UIApplication sharedApplication].delegate;
}

@end
