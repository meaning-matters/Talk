//
//  NSString_Common.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/12/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "NSString+Common.h"

@implementation NSString (NSString_Common)

#pragma mark - Popup display
- (void) displayToUserWithTitle:(NSString *)title andButton:(NSString *)button
{
    dispatch_block_t block = ^{
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:title message:self
                              delegate:self cancelButtonTitle:nil
                              otherButtonTitles:button, nil];
        [alert show];
    };
    
    if ([NSThread isMainThread])
    {
        block();
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}


#pragma mark - Date formatting
+ (NSString*)formatToShortDate:(NSDate*)date
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"MM dd, yyyy"];
    [dateFormat setDateStyle:NSDateFormatterLongStyle];

    return [dateFormat stringFromDate:date];
}


+ (NSString*)formatToSlashSeparatedDate:(NSDate*)date
{
    NSDateFormatter*dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"d/M/yy"];
    return [dateFormat stringFromDate:date];
}


+ (NSString*)formatToTime:(NSDate*)date
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"HH:mm"];

    return [dateFormat stringFromDate:date];    
}

@end
