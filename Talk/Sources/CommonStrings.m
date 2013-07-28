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
                                             @"Standard string indicating data is being loaded (from internet)\n"
                                             @"[iOS standard size].");
}


+ (NSString*)enableString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Enable", nil,
                                             [NSBundle mainBundle], @"Enable",
                                             @"Standard string for switching on something\n"
                                             @"[iOS standard size].");
}


+ (NSString*)nameString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Name", nil,
                                             [NSBundle mainBundle], @"Name",
                                             @"Standard string to label a name of something\n"
                                             @"[iOS standard size].");
}


+ (NSString*)nameFooterString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings NameFooter", nil,
                                             [NSBundle mainBundle],
                                             @"Enter a short descriptive name that is easy to remember.\n"
                                             @"Can be changed later.",
                                             @"Standard table footer text, telling that user must supply a name.");
}


+ (NSString*)requiredString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Required", nil,
                                             [NSBundle mainBundle], @"Required",
                                             @"Standard placeholder text in textfield, telling it needs to be filled in\n"
                                             @"[iOS standard size].");
}


+ (NSString*)numberString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Number", nil,
                                             [NSBundle mainBundle], @"Number",
                                             @"Standard string to label a phone number\n"
                                             @"[iOS standard size].");
}


+ (NSString*)monthString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Month", nil,
                                             [NSBundle mainBundle], @"month",
                                             @"Standard string for the singular of 'month'\n"
                                             @"[No size contraint].");
}


+ (NSString*)monthsString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Months", nil,
                                             [NSBundle mainBundle], @"months",
                                             @"Standard string for the plural of 'month'\n"
                                             @"[No size contraint].");
}

@end
