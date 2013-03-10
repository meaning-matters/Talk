//
//  CommonStrings.m
//  Talk
//
//  Created by Cornelis van der Bent on 23/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "CommonStrings.h"

@implementation CommonStrings

+ (NSString*)cancelString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Cancel", nil,
                                             [NSBundle mainBundle], @"Cancel",
                                             @"Standard string seen on [alert] buttons to cancel something\n"
                                             @"[iOS standard size].");
}


+ (NSString*)closeString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Close", nil,
                                             [NSBundle mainBundle], @"Close",
                                             @"Standard string seen on [alert] buttons to close something\n"
                                             @"[iOS standard size].");
}


+ (NSString*)okString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings OK", nil,
                                             [NSBundle mainBundle], @"OK",
                                             @"Standard string seen on [alert] buttons to OK something\n"
                                             @"[iOS standard size].");
}


+ (NSString*)buyString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Buy", nil,
                                             [NSBundle mainBundle], @"Buy",
                                             @"Standard string seen on [alert] buttons to confirm buying action\n"
                                             @"[iOS standard size].");
}


+ (NSString*)loadingString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Loading", nil,
                                             [NSBundle mainBundle], @"Loading...",
                                             @"Standard string indicing data is being loaded (from internet)\n"
                                             @"[iOS standard size].");
}

@end
