//
//  Keychain.m
//  Talk
//
//  Created by Cornelis van der Bent on 20/05/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//
//  Found here: http://software-security.sans.org/blog/2011/01/05/using-keychain-to-store-passwords-ios-iphone-ipad
//

#import "Keychain.h"
#import <Security/Security.h>

@implementation Keychain

+ (BOOL)saveString:(NSString*)inputString forKey:(NSString*)account
{
    BOOL result = YES;

    if (account == nil || inputString == nil)
    {
        NSLog(@"saveString failed: invalid parameter(s)!");
        result = NO;
    }
    else
    {
        NSMutableDictionary* query = [NSMutableDictionary dictionary];

        [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
        [query setObject:account forKey:(__bridge id)kSecAttrAccount];
        [query setObject:(__bridge id)kSecAttrAccessibleAlways forKey:(__bridge id)kSecAttrAccessible];

        OSStatus error = SecItemCopyMatching((__bridge CFDictionaryRef)query, NULL);
        if (error == errSecSuccess)
        {
            // Do update.
            NSDictionary* attributesToUpdate;
            attributesToUpdate = [NSDictionary dictionaryWithObject:[inputString dataUsingEncoding:NSUTF8StringEncoding]
                                                             forKey:(__bridge id)kSecValueData];

            error = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)attributesToUpdate);
            if (error != errSecSuccess)
            {
                NSLog(@"SecItemUpdate failed: %ld", error);
                result = NO;
            }
        }
        else if (error == errSecItemNotFound)
        {
            // Do add.
            [query setObject:[inputString dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];

            error = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
            if (error != errSecSuccess)
            {
                NSLog(@"SecItemAdd failed: %ld", error);
                result = NO;
            }
        }
        else
        {
            NSLog(@"SecItemCopyMatching failed: %ld", error);
            result = NO;
        }
    }

    return result;
}


+ (NSString*)getStringForKey:(NSString*)account
{
    NSString*   stringToReturn = nil;

    if (account == nil)
    {
        NSLog(@"getStringForKey failed: invalid parameter!");
    }
    else
    {
        NSMutableDictionary* query = [NSMutableDictionary dictionary];

        [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
        [query setObject:account forKey:(__bridge id)kSecAttrAccount];
        [query setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];

        NSData*   data    = nil;
        CFTypeRef refData = nil;
        OSStatus  error   = SecItemCopyMatching((__bridge CFDictionaryRef)query, &refData);
        data = (__bridge NSData*)(CFDataRef)refData;

        if (error == errSecSuccess)
        {
            stringToReturn = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
    }

    return stringToReturn;
}


+ (BOOL)deleteStringForKey:(NSString *)account
{
    BOOL result = YES;

    if (account == nil)
    {
        NSLog(@"deleteStringForKey failed: invalid parameter!");
        result = NO;
    }
    else
    {
        NSMutableDictionary *query = [NSMutableDictionary dictionary];

        [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
        [query setObject:account forKey:(__bridge id)kSecAttrAccount];

        OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
        if (status != errSecSuccess)
        {
            NSLog(@"SecItemDelete failed: %ld", status);
            result = NO;
        }
    }

    return result;
}

@end