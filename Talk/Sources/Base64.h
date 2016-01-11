//
//  Base64.h
//  Talk
//
//  Created by Cornelis van der Bent on 30/01/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Base64 : NSObject

+ (NSString*)encode:(const uint8_t*)input length:(size_t)length;
+ (NSString*)encode:(NSData*)rawBytes;
+ (NSData*)decode:(const char*)string length:(size_t)inputLength;
+ (NSData*)decode:(NSString*)string;

@end
