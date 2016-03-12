//
//  Strings.m
//  Talk
//
//  Created by Cornelis van der Bent on 23/11/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import "Strings.h"

@implementation Strings

#pragma mark - Common

+ (NSString*)cancelString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Cancel", nil, [NSBundle mainBundle],
                                             @"Cancel",
                                             @"Standard string seen on [alert] buttons to cancel something\n"
                                             @"[iOS standard size].");
}


+ (NSString*)closeString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Close", nil, [NSBundle mainBundle],
                                             @"Close",
                                             @"Standard string seen on [alert] buttons to close something\n"
                                             @"[iOS standard size].");
}


+ (NSString*)goString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Go", nil, [NSBundle mainBundle],
                                             @"Go",
                                             @"Standard string seen on [alert] buttons to indicate action\n"
                                             @"[iOS standard size].");
}


+ (NSString*)okString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings OK", nil, [NSBundle mainBundle],
                                             @"OK",
                                             @"Standard string seen on [alert] buttons to OK something\n"
                                             @"[iOS standard size].");
}


+ (NSString*)noString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings No", nil, [NSBundle mainBundle],
                                             @"No",
                                             @"Standard string seen on [alert] buttons to say no to something\n"
                                             @"[iOS standard size].");
}


+ (NSString*)yesString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Yes", nil, [NSBundle mainBundle],
                                             @"Yes",
                                             @"Standard string seen on [alert] buttons to say yes to something\n"
                                             @"[iOS standard size].");
}


+ (NSString*)buyString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Buy", nil, [NSBundle mainBundle],
                                             @"Buy",
                                             @"Standard string seen on [alert] buttons to confirm buying action\n"
                                             @"[iOS standard size].");
}


+ (NSString*)enableString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Enable", nil, [NSBundle mainBundle],
                                             @"Enable",
                                             @"Standard string for switching on something\n"
                                             @"[iOS standard size].");
}


+ (NSString*)nameString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Name", nil, [NSBundle mainBundle],
                                             @"Name",
                                             @"Standard string to label a name of something\n"
                                             @"[iOS standard size].");
}


+ (NSString*)nameFooterString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings NameFooter", nil, [NSBundle mainBundle],
                                             @"Enter a short descriptive name that is easy to remember. "
                                             @"Can be changed later.",
                                             @"Standard table footer text, telling that user must supply a name.");
}


+ (NSString*)requiredString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Required", nil, [NSBundle mainBundle],
                                             @"Required",
                                             @"Standard placeholder text in textfield, telling it needs to be filled in\n"
                                             @"[iOS standard size].");
}


+ (NSString*)optionalString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Optional", nil, [NSBundle mainBundle],
                                             @"Optional",
                                             @"Standard placeholder text in textfield, telling filling in is optional\n"
                                             @"[iOS standard size].");
}


+ (NSString*)detailsString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Details", nil, [NSBundle mainBundle],
                                             @"Details",
                                             @"Standard string to label detailed information\n"
                                             @"[iOS standard size].");
}


+ (NSString*)numberString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Number", nil, [NSBundle mainBundle],
                                             @"Number",
                                             @"Standard string to label a phone number\n"
                                             @"[iOS standard size].");
}


+ (NSString*)newNumberString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings New Number", nil, [NSBundle mainBundle],
                                             @"New Number",
                                             @"Standard string to label a new phone number\n"
                                             @"[iOS standard size].");
}


+ (NSString*)numbersString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Numbers", nil, [NSBundle mainBundle],
                                             @"Numbers",
                                             @"Standard string to label phone numbers\n"
                                             @"[iOS standard size].");
}


+ (NSString*)addressString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Address", nil, [NSBundle mainBundle],
                                             @"Address",
                                             @"Standard string to label an address\n"
                                             @"[iOS standard size].");
}


+ (NSString*)newAddressString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings New Address", nil, [NSBundle mainBundle],
                                             @"New Address",
                                             @"Standard string to label a new address\n"
                                             @"[iOS standard size].");
}


+ (NSString*)addressesString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Addresses", nil, [NSBundle mainBundle],
                                             @"Addresses",
                                             @"Standard string to label addresses\n"
                                             @"[iOS standard size].");
}


+ (NSString*)newDestinationString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings New Destination", nil, [NSBundle mainBundle],
                                             @"New Destination",
                                             @"Standard string to label a new phone call destination\n"
                                             @"[iOS standard size].");
}


+ (NSString*)destinationString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Destination", nil, [NSBundle mainBundle],
                                             @"Destination",
                                             @"Standard string to label a phone call destination\n"
                                             @"[iOS standard size].");
}


+ (NSString*)destinationsString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Destinations", nil, [NSBundle mainBundle],
                                             @"Destinations",
                                             @"Standard string to label phone call destinations\n"
                                             @"[iOS standard size].");
}


+ (NSString*)recordingString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Recording", nil, [NSBundle mainBundle],
                                             @"Recording",
                                             @"Standard string to label voice recording\n"
                                             @"[iOS standard size].");
}


+ (NSString*)recordingsString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Recordings", nil, [NSBundle mainBundle],
                                             @"Recordings",
                                             @"Standard string to label voice recordings\n"
                                             @"[iOS standard size].");
}


+ (NSString*)newPhoneString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings New Phone", nil, [NSBundle mainBundle],
                                             @"New Phone",
                                             @"Standard string to label a new telephone device\n"
                                             @"[iOS standard size].");
}


+ (NSString*)phoneString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Phone", nil, [NSBundle mainBundle],
                                             @"Phone",
                                             @"Standard string to label a telephone device\n"
                                             @"[iOS standard size].");
}


+ (NSString*)phonesString;
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Phones", nil, [NSBundle mainBundle],
                                             @"Phones",
                                             @"Standard string to label telephone devices\n"
                                             @"[iOS standard size].");
}


+ (NSString*)creditString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Credit", nil, [NSBundle mainBundle],
                                             @"Credit",
                                             @"Standard string to label a (calling) credit\n"
                                             @"[iOS standard size].");
}


+ (NSString*)recentsString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Recents", nil, [NSBundle mainBundle],
                                             @"Recents",
                                             @"Standard string to label recent calls\n"
                                             @"[iOS standard size].");
}


+ (NSString*)contactsString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Contacts", nil, [NSBundle mainBundle],
                                             @"Contacts",
                                             @"Standard string to label people\n"
                                             @"[iOS standard size].");
}


// Need many more for i18n: http://unicode.org/repos/cldr-tmp/trunk/diff/supplemental/language_plural_rules.html
+ (NSString*)monthString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Month", nil, [NSBundle mainBundle],
                                             @"month",
                                             @"Standard string for the singular of 'month'\n"
                                             @"[No size contraint].");
}


+ (NSString*)monthsString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Months", nil, [NSBundle mainBundle],
                                             @"months",
                                             @"Standard string for the plural of 'month'\n"
                                             @"[No size contraint].");
}


+ (NSString*)callString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Call", nil, [NSBundle mainBundle],
                                             @"Call",
                                             @"Standard string for on button to initiate a phone call\n"
                                             @"[No size contraint, use iOS naming].");
}


+ (NSString*)companyString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Company", nil, [NSBundle mainBundle],
                                             @"Company",
                                             @"Title indicating a company (opposed to personal Mr. or Ms.).\n"
                                             @"[One line].");
}


+ (NSString*)salutationString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Salutation", nil, [NSBundle mainBundle],
                                             @"Title",
                                             @"Standard label for salutation/title.\n"
                                             @"[One line].");
}


+ (NSString*)firstNameString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings FirstName", nil, [NSBundle mainBundle],
                                             @"First Name",
                                             @"Standard label for person's first name.\n"
                                             @"[One line].");
}


+ (NSString*)lastNameString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings LastName", nil, [NSBundle mainBundle],
                                             @"Last Name",
                                             @"Standard label for person's last name.\n"
                                             @"[One line].");
}


+ (NSString*)streetString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Street", nil, [NSBundle mainBundle],
                                             @"Street",
                                             @"Standard label for street name (without building/number).\n"
                                             @"[One line].");
}


+ (NSString*)buildingNumberString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings BuildingNumber", nil, [NSBundle mainBundle],
                                             @"Building Number",
                                             @"Standard label for building/number (in home/company address).\n"
                                             @"[One line].");
}


+ (NSString*)buildingLetterString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Building", nil, [NSBundle mainBundle],
                                             @"Building Letter",
                                             @"Standard label for building/number (in home/company address).\n"
                                             @"[One line].");
}


+ (NSString*)cityString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings City", nil, [NSBundle mainBundle],
                                             @"City",
                                             @"Standard label for city.\n"
                                             @"[One line].");
}


+ (NSString*)postcodeString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Postcode", nil, [NSBundle mainBundle],
                                             @"Postode",
                                             @"Standard label for postcode.\n"
                                             @"[One line].");
}


+ (NSString*)stateString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings State", nil, [NSBundle mainBundle],
                                             @"State",
                                             @"Standard label for state name (in home/company address).\n"
                                             @"[One line].");
}


+ (NSString*)countryString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Country", nil, [NSBundle mainBundle],
                                             @"Country",
                                             @"Standard label for a country name.\n"
                                             @"[No size contraint].");
}


+ (NSString*)homeCountryString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings HomeCountry", nil, [NSBundle mainBundle],
                                             @"Home Country",
                                             @"Standard label the user's home country (related to phone numbers).\n"
                                             @"[No size contraint].");
}


+ (NSString*)callerIdString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings CallerID", nil, [NSBundle mainBundle],
                                             @"Caller ID",
                                             @"Standard label for a phone number the person you call sees.\n"
                                             @"[No size contraint].");
}


+ (NSString*)typeString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings PhoneNumberType", nil, [NSBundle mainBundle],
                                             @"Type",
                                             @"Standard label for the type of phone number (e.g. geographic, toll-free).\n"
                                             @"[No size contraint].");
}


+ (NSString*)areaCodeString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings PhoneNumberAreaCode", nil, [NSBundle mainBundle],
                                             @"Area Code",
                                             @"Standard label for a phone number's area code (e.g. 0800).\n"
                                             @"[No size contraint].");
}


+ (NSString*)areaString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings PhoneNumberArea", nil, [NSBundle mainBundle],
                                             @"Area",
                                             @"Standard label for a phone number's area (or city) name (e.g. Paris).\n"
                                             @"[No size contraint].");
}


+ (NSString*)defaultString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Default", nil, [NSBundle mainBundle],
                                             @"Default",
                                             @"Standard label for a default value/selection/number/....\n"
                                             @"[No size contraint].");
}


+ (NSString*)synchronizeWithServerString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings SynchronizeWithServer", nil, [NSBundle mainBundle],
                                             @"Synchronize with server",
                                             @"Standard label to indicate things being loaded from internet server\n"
                                             @"[No size contraint].");
}


+ (NSString*)endString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings End", nil, [NSBundle mainBundle],
                                             @"End",
                                             @"Standard string for ending phone call\n"
                                             @"[No size contraint].");
}


+ (NSString*)agreeString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings Agree", nil, [NSBundle mainBundle],
                                             @"Agree",
                                             @"Standard string for agree action (e.g. for terms and conditions)\n"
                                             @"[Button size].");
}


+ (NSString*)iOsSettingsString
{
    return NSLocalizedStringWithDefaultValue(@"General:CommonStrings iOS Settings", nil, [NSBundle mainBundle],
                                             @"Settings",
                                             @"Name of the iOS Settings app\n"
                                             @"[Button size].");
}

@end
