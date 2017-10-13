//
//  NSString_Common.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/12/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NSString+Common.h"

@implementation NSString (NSString_Common)

#pragma mark - Popup display

- (void) displayToUserWithTitle:(NSString *)title andButton:(NSString *)button
{
    dispatch_block_t block = ^
    {
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


- (NSString*)stringByRemovingWhiteSpace
{
    NSArray* words = [self componentsSeparatedByCharactersInSet :[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    return [words componentsJoinedByString:@""];
}



- (NSString*)stringByTrimmingLeadingWhiteSpace
{
    NSRange range = [self rangeOfString:@"^\\s*" options:NSRegularExpressionSearch];

    return [self stringByReplacingCharactersInRange:range withString:@""];
}


- (NSString*)stringByTrimmingTrailingWhiteSpace
{
    NSRange range = [self rangeOfString:@"\\s*$" options:NSRegularExpressionSearch];

    return [self stringByReplacingCharactersInRange:range withString:@""];
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


- (NSString*)capitalizedFirstLetter
{
    if (self.length <= 1)
    {
         return self.capitalizedString;
    }
    else
    {
        return [NSString stringWithFormat:@"%@%@", [[self substringToIndex:1] uppercaseString], [self substringFromIndex:1]];
    }
}

@end
