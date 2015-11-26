//
//  NSString_Common.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/12/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (NSString_Common)

- (void)displayToUserWithTitle:(NSString*)title andButton:(NSString*)button;

- (NSString*)stringByRemovingWhiteSpace;

+ (NSString*)formatToShortDate:(NSDate*)date;

+ (NSString*)formatToSlashSeparatedDate:(NSDate*)date;

+ (NSString*)formatToTime:(NSDate*)date;


@end
