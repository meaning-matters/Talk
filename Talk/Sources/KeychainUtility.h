//
//  KeychainUtility.h
//  Talk
//
//  Created by Cornelis van der Bent on 07/12/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KeychainUtility : NSObject

+ (NSString*)getPasswordForUsername:(NSString*)username
                     andServiceName:(NSString*)serviceName
                              error:(NSError**)error;

+ (BOOL)storeUsername:(NSString*)username
          andPassword:(NSString*)password
       forServiceName:(NSString*)serviceName
       updateExisting:(BOOL)updateExisting
                error:(NSError**)error;

+ (BOOL)deleteItemForUsername:(NSString*)username
               andServiceName:(NSString*)serviceName
                        error:(NSError**)error;

@end
