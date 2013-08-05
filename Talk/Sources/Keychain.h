//
//  Keychain.h
//  Talk
//
//  Created by Cornelis van der Bent on 20/05/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Keychain : NSObject

+ (BOOL)saveString:(NSString*)inputString forKey:(NSString*)account;

+ (NSString *)getStringForKey:(NSString*)account;

+ (BOOL)deleteStringForKey:(NSString*)account;

@end
