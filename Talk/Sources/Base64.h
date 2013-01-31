//
//  Base64.h
//  Talk
//
//  Created by Cornelis van der Bent on 30/01/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Base64 : NSObject

+ (NSString*)encode:(const uint8_t*)input length:(NSInteger)length;
+ (NSString*)encode:(NSData*)rawBytes;
+ (NSData*)decode:(const char*)string length:(NSInteger)inputLength;
+ (NSData*)decode:(NSString*)string;

@end
