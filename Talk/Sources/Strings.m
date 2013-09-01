//
//  Strings.m
//  Talk
//
//  Created by Cornelis van der Bent on 23/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "Strings.h"

@implementation Strings

#pragma mark - Common

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


+ (NSString*)noString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings No", nil,
                                             [NSBundle mainBundle], @"No",
                                             @"Standard string seen on [alert] buttons to say no to something\n"
                                             @"[iOS standard size].");
}


+ (NSString*)yesString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Yes", nil,
                                             [NSBundle mainBundle], @"Yes",
                                             @"Standard string seen on [alert] buttons to say yes to something\n"
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


+ (NSString*)optionalString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Optional", nil,
                                             [NSBundle mainBundle], @"Optional",
                                             @"Standard placeholder text in textfield, telling filling in is optional\n"
                                             @"[iOS standard size].");
}


+ (NSString*)numberString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Number", nil,
                                             [NSBundle mainBundle], @"Number",
                                             @"Standard string to label a phone number\n"
                                             @"[iOS standard size].");
}


+ (NSString*)creditString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Number", nil,
                                             [NSBundle mainBundle], @"Credit",
                                             @"Standard string to label a (calling) credit\n"
                                             @"[iOS standard size].");
}


// Need many more for i18n: http://unicode.org/repos/cldr-tmp/trunk/diff/supplemental/language_plural_rules.html
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


+ (NSString*)callString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Call", nil,
                                             [NSBundle mainBundle], @"Call",
                                             @"Standard string for on button to initiate a phone call\n"
                                             @"[No size contraint, use iOS naming].");
}


+ (NSString*)msString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Miss", nil,
                                             [NSBundle mainBundle], @"Ms.",
                                             @"Title for woman (miss), both married or not married.\n"
                                             @"[One line].");
}


+ (NSString*)mrString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Mister", nil,
                                             [NSBundle mainBundle], @"Mr.",
                                             @"Title for man (mister), both married or not married.\n"
                                             @"[One line].");
}


+ (NSString*)companyString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Company", nil,
                                             [NSBundle mainBundle], @"Company",
                                             @"Title indicating a company (opposed to personal Mr. or Ms.).\n"
                                             @"[One line].");
}


+ (NSString*)salutationString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Salutation", nil,
                                             [NSBundle mainBundle], @"Title",
                                             @"Standard label for salutation/title.\n"
                                             @"[One line].");
}


+ (NSString*)firstNameString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings FirstName", nil,
                                             [NSBundle mainBundle], @"First Name",
                                             @"Standard label for person's first name.\n"
                                             @"[One line].");
}


+ (NSString*)lastNameString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings LastName", nil,
                                             [NSBundle mainBundle], @"Last Name",
                                             @"Standard label for person's last name.\n"
                                             @"[One line].");
}


+ (NSString*)streetString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Street", nil,
                                             [NSBundle mainBundle], @"Street",
                                             @"Standard label for street name (without building/number).\n"
                                             @"[One line].");
}


+ (NSString*)buildingString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Building", nil,
                                             [NSBundle mainBundle], @"Building",
                                             @"Standard label for building/number (in home/company address).\n"
                                             @"[One line].");
}


+ (NSString*)cityString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings City", nil,
                                             [NSBundle mainBundle], @"City",
                                             @"Standard label for city.\n"
                                             @"[One line].");
}


+ (NSString*)zipCodeString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings ZIPCode", nil,
                                             [NSBundle mainBundle], @"ZIP Code",
                                             @"Standard label for ZIP code.\n"
                                             @"[One line].");
}


+ (NSString*)stateString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings State", nil,
                                             [NSBundle mainBundle], @"State",
                                             @"Standard label for state name (in home/company address).\n"
                                             @"[One line].");
}


+ (NSString*)countryString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Country", nil,
                                             [NSBundle mainBundle], @"Country",
                                             @"Standard label for a country name.\n"
                                             @"[No size contraint].");
}


+ (NSString*)typeString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings PhoneNumberType", nil,
                                             [NSBundle mainBundle], @"Type",
                                             @"Standard label for the type of phone number (e.g. geographic, toll-free).\n"
                                             @"[No size contraint].");
}


+ (NSString*)areaCodeString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings PhoneNumberAreaCode", nil,
                                             [NSBundle mainBundle], @"Area Code",
                                             @"Standard label for a phone number's area code (e.g. 0800).\n"
                                             @"[No size contraint].");
}


+ (NSString*)areaString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings PhoneNumberArea", nil,
                                             [NSBundle mainBundle], @"Area",
                                             @"Standard label for a phone number's area (or city) name (e.g. Paris).\n"
                                             @"[No size contraint].");
}


+ (NSString*)defaultString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Default", nil,
                                             [NSBundle mainBundle], @"Default",
                                             @"Standard label for a default value/selection/number/....\n"
                                             @"[No size contraint].");
}

@end
