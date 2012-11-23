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
                                             [NSBundle mainBundle], @"Cancel",
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

@end
