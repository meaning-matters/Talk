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

+ (void)saveString:(NSString*)inputString forKey:(NSString*)account
{
#warning //### Replace this assert with something gentle, because it happened sometimes when server failed.
    NSAssert(account     != nil, @"Invalid account");
    NSAssert(inputString != nil, @"Invalid string");

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
        NSAssert1(error == errSecSuccess, @"SecItemUpdate failed: %ld", error);
    }
    else if (error == errSecItemNotFound)
    {
        // Do add.
        [query setObject:[inputString dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];

        error = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
        NSAssert1(error == errSecSuccess, @"SecItemAdd failed: %ld", error);
	}
    else
    {
        NSAssert1(NO, @"SecItemCopyMatching failed: %ld", error);
    }
}


+ (NSString*)getStringForKey:(NSString*)account
{
    NSAssert(account != nil, @"Invalid account");

    NSMutableDictionary* query = [NSMutableDictionary dictionary];

    [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [query setObject:account forKey:(__bridge id)kSecAttrAccount];
    [query setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];

    NSData*     data = nil;
    CFTypeRef   refData = nil;

    OSStatus    error = SecItemCopyMatching((__bridge CFDictionaryRef)query, &refData);
    data = (__bridge NSData*)(CFDataRef)refData;

    NSString*   stringToReturn = nil;
    if (error == errSecSuccess)
    {
        stringToReturn = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }

    return stringToReturn;
}


+ (void)deleteStringForKey:(NSString *)account
{
    NSAssert(account != nil, @"Invalid account");

    NSMutableDictionary *query = [NSMutableDictionary dictionary];

    [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [query setObject:account forKey:(__bridge id)kSecAttrAccount];

    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
    if (status != errSecSuccess)
    {
        NSLog(@"SecItemDelete failed: %ld", status);
    }
}

@end