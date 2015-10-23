//
//  Keychain.m
//  Talk
//
//  Created by Cornelis van der Bent on 20/05/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//
//  Found here: http://software-security.sans.org/blog/2011/01/05/using-keychain-to-store-passwords-ios-iphone-ipad
//
//  In iOS 8 there's a severe issue that causes all keychain calls to fail
//  with -34018 (errSecMissingEntitlement).  This is discussed here:
//  https://devforums.apple.com/thread/246122?start=50&tstart=0 and here
//  http://stackoverflow.com/q/20344255/1971013 and in various other posts.
//  What I've done so far is remove wildcard provisioning profiles and
//  making this module non-ARC.  Best suggestions were given in Apple forum
//  by Kevin Hawkins.
//
//  Because the problem persisted, I'm now caching the values.  Really unsafe,
//  but I've also asked Apple for a permanent solution.
//

#import "Keychain.h"
#import <Security/Security.h>


@implementation Keychain

+ (NSMutableDictionary*)sharedStrings
{
    static NSMutableDictionary* strings;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        strings = [NSMutableDictionary dictionary];
    });

    return strings;
}


+ (BOOL)saveString:(NSString*)inputString forKey:(NSString*)account
{
    BOOL result = YES;

    if (account == nil || inputString == nil)
    {
        NBLog(@"saveString failed: invalid parameter(s)!");
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
                NBLog(@"SecItemUpdate failed: %d", (int)error);
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
                NBLog(@"SecItemAdd failed: %d", (int)error);
                result = NO;
            }
        }
        else
        {
            NBLog(@"SecItemCopyMatching failed: %d", (int)error);
            result = NO;
        }
    }

    if (result == YES)
    {
        [[self sharedStrings] setObject:inputString forKey:account];
    }

    return result;
}


+ (NSString*)getStringForKey:(NSString*)account
{
    NSString* stringToReturn = nil;

    if (account == nil)
    {
        NBLog(@"getStringForKey failed: invalid parameter!");
    }
    else if ([[self sharedStrings] objectForKey:account] != nil)
    {
        stringToReturn = [[self sharedStrings] objectForKey:account];
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

            [[self sharedStrings] setObject:stringToReturn forKey:account];
        }
    }

    return stringToReturn;
}


+ (BOOL)deleteStringForKey:(NSString*)account
{
    BOOL result = YES;

    if (account == nil)
    {
        NBLog(@"deleteStringForKey failed: invalid parameter!");
        result = NO;
    }
    else
    {
        [[self sharedStrings] removeObjectForKey:account];

        NSMutableDictionary *query = [NSMutableDictionary dictionary];

        [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
        [query setObject:account forKey:(__bridge id)kSecAttrAccount];

        OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
        if (status != errSecSuccess)
        {
            NBLog(@"SecItemDelete failed: %d", (int)status);
            result = NO;
        }
    }

    return result;
}

@end