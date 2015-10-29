//
//  NBContact.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/12/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "NBContact.h"
#ifndef NB_STANDALONE
#import "DataManager.h"
#import "CallManager.h"
#import "Settings.h"
#endif

@implementation NBContact

@synthesize isNewContact;

- (instancetype)initWithContact:(ABRecordRef)contactParam
{
    if (self = [super init])
    {
        self.contactRef = contactParam;
    }
    return self;
}

#pragma mark - Name management
+ (NSString*)getStringProperty:(ABPropertyID)property forContact:(ABRecordRef)contactRef
{
    NSString * result = (__bridge NSString *)(ABRecordCopyValue(contactRef, property));
    if ([result isKindOfClass:[NSString class]])
    {
        return result;
    }
    return nil;
}

#pragma mark - Support for labeling
+ (NSMutableAttributedString*)getListRepresentation:(ABRecordRef)contactRef
{
    /*
        If possible, show prefix, first, middle, last, and suffix (last Bold)
        If no lastname, first name bold
        Else, show the rest regular
     */
    //Set the attributed string (my number: <NUMBER> where my number is regular and the number itself is bold)
    NSDictionary * regularAttributes        = [NSDictionary dictionaryWithObjectsAndKeys:
                                              [UIFont systemFontOfSize:20], NSFontAttributeName, nil];
    NSDictionary * boldAttributes           = [NSDictionary dictionaryWithObjectsAndKeys:
                                               [UIFont boldSystemFontOfSize:20], NSFontAttributeName, nil];
    
    //Determine the name format
    NSMutableArray * primaryListRepresentation = [NSMutableArray arrayWithObject:[NSNumber numberWithInt:kABPersonPrefixProperty]];
    
    //Used to determine wether to make the first-or lastname bold
    ABPersonSortOrdering sortOrdering = ABPersonGetSortOrdering();
    
    //Used to determine in what order to show the name
    ABPersonCompositeNameFormat nameFormat = ABPersonGetCompositeNameFormatForRecord(NULL);
    
    if (nameFormat == kABPersonCompositeNameFormatFirstNameFirst)
    {
        [primaryListRepresentation addObjectsFromArray:@
        [
            [NSNumber numberWithInt:kABPersonFirstNameProperty],
            [NSNumber numberWithInt:kABPersonMiddleNameProperty],
            [NSNumber numberWithInt:kABPersonLastNameProperty],
            [NSNumber numberWithInt:kABPersonSuffixProperty]]
        ];
    }
    else
    {
        [primaryListRepresentation addObjectsFromArray:@
        [
            [NSNumber numberWithInt:kABPersonLastNameProperty],
            [NSNumber numberWithInt:kABPersonFirstNameProperty],
            [NSNumber numberWithInt:kABPersonMiddleNameProperty],
            [NSNumber numberWithInt:kABPersonSuffixProperty]]
        ];
    }
    
    NSRange boldRange = NSMakeRange(-1, 0);
    NSMutableString * listRepresentation = [NSMutableString string];
    BOOL hasFirstName = [[NBContact getStringProperty:kABPersonLastNameProperty forContact:contactRef] length] > 0;
    BOOL hasLastName  = [[NBContact getStringProperty:kABPersonLastNameProperty forContact:contactRef] length] > 0;
    for (NSNumber * propertyNum in primaryListRepresentation)
    {
        ABPropertyID propertyID = (ABPropertyID)[propertyNum intValue];
        NSString * propertyString = [NBContact getStringProperty:propertyID forContact:contactRef];
        if (propertyString != nil && [propertyString length] > 0)
        {
            //Check to build the bold-first and lastname
            if (((propertyID == kABPersonFirstNameProperty && sortOrdering == kABPersonSortByFirstName) || !hasFirstName) ||
                ((propertyID == kABPersonLastNameProperty && sortOrdering == kABPersonSortByLastName) || !hasLastName))
            {
                //Set the range
                boldRange.location =  [listRepresentation length];
                boldRange.length = [propertyString length];
            }
            
            //Append the string
            [listRepresentation appendFormat:@"%@ ", propertyString];
        }
    }
    
    //If no name part is available, show Company Bold
    if ([listRepresentation length] == 0)
    {
        NSString * propertyString = [NBContact getStringProperty:kABPersonOrganizationProperty forContact:contactRef];
        if (propertyString != nil)
        {
            [listRepresentation appendString:propertyString];
            boldRange = NSMakeRange(0, [listRepresentation length]);
        }
    }
    
    //If no company, show email bold
    if ([listRepresentation length] == 0)
    {
        NSString * propertyString = [NBContact getAvailableProperty:kABPersonEmailProperty from:contactRef];
        if (propertyString != nil)
        {
            [listRepresentation appendString:propertyString];
            boldRange = NSMakeRange(0, [listRepresentation length]);
        }
    }
    
    //If no email, show number bold
    if ([listRepresentation length] == 0)
    {
        NSString* propertyString = [NBContact getAvailableProperty:kABPersonPhoneProperty from:contactRef];
#ifndef NB_STANDALONE
        propertyString = [[NBAddressBookManager sharedManager].delegate formatNumber:propertyString];
#endif
        if (propertyString != nil)
        {
            [listRepresentation appendString:propertyString];
            boldRange = NSMakeRange(0, [listRepresentation length]);
        }
    }
    
    //Else, show 'no name'
    if ([listRepresentation length] == 0)
    {
        regularAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont italicSystemFontOfSize:20], NSFontAttributeName, nil];
        [listRepresentation appendString:NSLocalizedString(@"CNT_NO_NAME", @"")];
    }
    
    //Set the attributes
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc]
                                                 initWithString:listRepresentation
                                                 attributes:regularAttributes];
    
    if (boldRange.location != -1)
    {
        [attributedText setAttributes:boldAttributes range:boldRange];
    }

    return attributedText;
}


#pragma mark - Image support
- (UIImage*)getImage:(BOOL)original
{
    if (original)
    {
        return [UIImage imageWithData:(__bridge NSData *)ABPersonCopyImageData(self.contactRef)];
    }
    else
    {
        return selectedImage;
    }
}


- (void)setImage:(UIImage*)image
{
    selectedImage = image;
}

#pragma mark - Check to see if a contact is a company
- (BOOL)isCompany
{
    if(([NBContact getStringProperty:kABPersonFirstNameProperty forContact:self.contactRef] != nil ||
        [NBContact getStringProperty:kABPersonFirstNamePhoneticProperty forContact:self.contactRef] != nil ||
        [NBContact getStringProperty:kABPersonMiddleNamePhoneticProperty forContact:self.contactRef] != nil ||
        [NBContact getStringProperty:kABPersonMiddleNameProperty forContact:self.contactRef] != nil ||
        [NBContact getStringProperty:kABPersonLastNameProperty forContact:self.contactRef] != nil ||
        [NBContact getStringProperty:kABPersonFirstNameProperty forContact:self.contactRef] != nil) ||
       [NBContact getStringProperty:kABPersonOrganizationProperty forContact:self.contactRef] == nil)
    {
        return NO;
    }
    else
    {
        return YES;
    }
}


#pragma mark - Saving the entire system
- (void)save:(NSMutableArray*)personCellStructure
{
    //If we don't have a contactref, create one
    if (self.contactRef == nil)
    {
        self.contactRef = ABPersonCreate();
    }
    
    CFErrorRef error = NULL;
    
    //Save the name properties
    NSMutableArray * nameArray = [personCellStructure objectAtIndex:CC_NAME];
    ABRecordSetValue(self.contactRef, kABPersonPrefixProperty,
                     (__bridge CFTypeRef)(((NBPersonCellInfo*)[nameArray objectAtIndex:0]).textValue), NULL);
    ABRecordSetValue(self.contactRef, kABPersonFirstNameProperty,
                     (__bridge CFTypeRef)(((NBPersonCellInfo*)[nameArray objectAtIndex:1]).textValue), NULL);
    ABRecordSetValue(self.contactRef, kABPersonFirstNamePhoneticProperty,
                     (__bridge CFTypeRef)(((NBPersonCellInfo*)[nameArray objectAtIndex:2]).textValue), NULL);
    ABRecordSetValue(self.contactRef, kABPersonMiddleNameProperty,
                     (__bridge CFTypeRef)(((NBPersonCellInfo*)[nameArray objectAtIndex:3]).textValue), NULL);
    ABRecordSetValue(self.contactRef, kABPersonLastNameProperty,
                     (__bridge CFTypeRef)(((NBPersonCellInfo*)[nameArray objectAtIndex:4]).textValue), NULL);
    ABRecordSetValue(self.contactRef, kABPersonLastNamePhoneticProperty,
                     (__bridge CFTypeRef)(((NBPersonCellInfo*)[nameArray objectAtIndex:5]).textValue), NULL);
    ABRecordSetValue(self.contactRef, kABPersonSuffixProperty,
                     (__bridge CFTypeRef)(((NBPersonCellInfo*)[nameArray objectAtIndex:6]).textValue), NULL);
    ABRecordSetValue(self.contactRef, kABPersonNicknameProperty,
                     (__bridge CFTypeRef)(((NBPersonCellInfo*)[nameArray objectAtIndex:7]).textValue), NULL);
    ABRecordSetValue(self.contactRef, kABPersonJobTitleProperty,
                     (__bridge CFTypeRef)(((NBPersonCellInfo*)[nameArray objectAtIndex:8]).textValue), NULL);
    ABRecordSetValue(self.contactRef, kABPersonDepartmentProperty,
                     (__bridge CFTypeRef)(((NBPersonCellInfo*)[nameArray objectAtIndex:9]).textValue), NULL);
    ABRecordSetValue(self.contactRef, kABPersonOrganizationProperty,
                     (__bridge CFTypeRef)(((NBPersonCellInfo*)[nameArray objectAtIndex:10]).textValue), NULL);
    
    //Numbers
    NSArray * numberArray = [personCellStructure objectAtIndex:CC_NUMBER];
    if ([numberArray count] > 0)
    {
        ABMutableMultiValueRef numberMulti = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        for (NBPersonCellInfo * numberInfo in numberArray)
        {
            if ([numberInfo.textValue length] > 0)
            {
                ABMultiValueAddValueAndLabel(numberMulti, (__bridge CFTypeRef)(numberInfo.textValue), (__bridge CFStringRef)(numberInfo.labelTitle), NULL);
            }
        }

        ABRecordSetValue(self.contactRef, kABPersonPhoneProperty, numberMulti, &error);
    }
    
    //Emails
    NSArray * emailArray = [personCellStructure objectAtIndex:CC_EMAIL];
    if ([emailArray count] > 0)
    {
        ABMutableMultiValueRef emailMulti = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        for (NBPersonCellInfo * emailInfo in emailArray)
        {
            if ([emailInfo.textValue length] > 0)
            {
                ABMultiValueAddValueAndLabel(emailMulti, (__bridge CFTypeRef)(emailInfo.textValue), (__bridge CFStringRef)(emailInfo.labelTitle), NULL);
            }
        }

        ABRecordSetValue(self.contactRef, kABPersonEmailProperty, emailMulti, &error);
    }
    
    //Homepages
    NSArray * homepageArray = [personCellStructure objectAtIndex:CC_HOMEPAGE];
    if ([homepageArray count] > 0)
    {
        ABMutableMultiValueRef homepageMulti = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        for (NBPersonCellInfo * homepageInfo in homepageArray)
        {
            if ([homepageInfo.textValue length] > 0)
            {
                ABMultiValueAddValueAndLabel(homepageMulti, (__bridge CFTypeRef)(homepageInfo.textValue), (__bridge CFStringRef)(homepageInfo.labelTitle), NULL);
            }
        }

        ABRecordSetValue(self.contactRef, kABPersonURLProperty, homepageMulti, &error);
    }
    
    //Birthday
    NSArray * birthdayArray = [personCellStructure objectAtIndex:CC_BIRTHDAY];
    if ([birthdayArray count] > 0)
    {
        ABRecordSetValue(self.contactRef, kABPersonBirthdayProperty, (__bridge CFTypeRef)((NBPersonCellInfo*)[birthdayArray objectAtIndex:0]).dateValue, NULL);
    }
    else
    {
        ABRecordRemoveValue(self.contactRef, kABPersonBirthdayProperty, nil);
    }
    
    //Anniversaries
    NSArray * anniArray = [personCellStructure objectAtIndex:CC_OTHER_DATES];
    if ([anniArray count] > 0)
    {
        ABMutableMultiValueRef anniMulti = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        for (NBPersonCellInfo * anniInfo in anniArray)
        {
            if (anniInfo.dateValue != nil)
            {
                ABMultiValueAddValueAndLabel(anniMulti, (__bridge CFTypeRef)(anniInfo.dateValue), (__bridge CFStringRef)(anniInfo.labelTitle), NULL);
            }
        }

        ABRecordSetValue(self.contactRef, kABPersonDateProperty, anniMulti, &error);
    }
    
    //Related contacts
    NSArray * relatedArray = [personCellStructure objectAtIndex:CC_RELATED_CONTACTS];
    if ([relatedArray count] > 0)
    {
        ABMutableMultiValueRef relatedMulti = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        for (NBPersonCellInfo * relatedInfo in relatedArray)
        {
            if (relatedInfo.textValue != nil)
            {
                ABMultiValueAddValueAndLabel(relatedMulti, (__bridge CFTypeRef)(relatedInfo.textValue), (__bridge CFStringRef)(relatedInfo.labelTitle), NULL);
            }
        }

        ABRecordSetValue(self.contactRef, kABPersonRelatedNamesProperty, relatedMulti, &error);
    }
    
    //Social
    NSArray * socialArray = [personCellStructure objectAtIndex:CC_SOCIAL];
    if ([socialArray count] > 0)
    {
        ABMutableMultiValueRef social = ABMultiValueCreateMutable(kABMultiDictionaryPropertyType);
        for (NBPersonCellInfo * cellInfo in socialArray)
        {
            if ([cellInfo.textValue length] > 0)
            {
                NSMutableDictionary * socialDict = [NSMutableDictionary dictionary];
                [socialDict setObject:cellInfo.labelTitle forKey:(NSString*)kABPersonSocialProfileServiceKey];
                [socialDict setObject:cellInfo.textValue forKey:(NSString*)kABPersonSocialProfileUsernameKey];
                ABMultiValueAddValueAndLabel(social, (__bridge CFTypeRef)(socialDict), kABHomeLabel, NULL);
            }
        }

        ABRecordSetValue(self.contactRef, kABPersonSocialProfileProperty, social, NULL);
    }
    
    //IM
    NSArray * IMArray = [personCellStructure objectAtIndex:CC_IM];
    if ([IMArray count] > 0)
    {
        ABMutableMultiValueRef im = ABMultiValueCreateMutable(kABMultiDictionaryPropertyType);
        for (NBPersonCellInfo * cellInfo in IMArray)
        {
            if ([cellInfo.textValue length] > 0)
            {
                NSMutableDictionary * imDict = [NSMutableDictionary dictionary];
                [imDict setObject:cellInfo.IMType forKey:(NSString*)kABPersonInstantMessageServiceKey];
                [imDict setObject:cellInfo.textValue forKey:(NSString*)kABPersonInstantMessageUsernameKey];
                ABMultiValueAddValueAndLabel(im, (__bridge CFTypeRef)(imDict), (__bridge CFStringRef)cellInfo.labelTitle, NULL);
            }
        }

        ABRecordSetValue(self.contactRef, kABPersonInstantMessageProperty, im, NULL);
    }
    
    //Notes
    NSArray * noteArray = [personCellStructure objectAtIndex:CC_NOTES];
    if ([noteArray count] > 0)
    {
        [self saveNotes:((NBPersonCellInfo*)[noteArray objectAtIndex:0]).textValue];
    }
    else
    {
        [self saveNotes:nil];
    }
    
    //Addresses
    NSMutableArray* addressArray = [personCellStructure objectAtIndex:CC_ADDRESS];
    if ([addressArray count] > 0)
    {
        ABMutableMultiValueRef addresses = ABMultiValueCreateMutable(kABMultiDictionaryPropertyType);
        for (int i = 0; i < [addressArray count]; i++)
        {
            NBPersonCellAddressInfo * addressInfo = [addressArray objectAtIndex:i];
            //Filter out empty addresses
            if ([addressInfo.city length]       == 0 &&
                [addressInfo.ZIP length]        == 0 &&
                [addressInfo.state length]      == 0 &&
                [addressInfo.streetLines count] == 0)
            {
                //Remove the cell and continue at the same position
                [addressArray removeObject:addressInfo];
                i--;
            }
            else
            {
                NSMutableDictionary * addDict = [NSMutableDictionary dictionary];
                //Build up the street-label
                NSMutableString * streetString = [NSMutableString string];
                for (int i = 0; i < [addressInfo.streetLines count]; i++)
                {
                    NSString * curStreet = [addressInfo.streetLines objectAtIndex:i];
                    if ([curStreet length] > 0)
                    {
                        [streetString appendString:curStreet];
                    }

                    if (i != [addressInfo.streetLines count] - 1)
                    {
                        [streetString appendString:@"\n"];
                    }
                }

                [addDict setObject:[NSString stringWithString:streetString] forKey:ADDRESS_KEY_STREET];
                if ([addressInfo.city length] > 0)
                {
                    [addDict setObject:addressInfo.city     forKey:ADDRESS_KEY_CITY];
                }

                if ([addressInfo.ZIP length] > 0)
                {
                    [addDict setObject:addressInfo.ZIP      forKey:ADDRESS_KEY_ZIP];
                }

                if ([addressInfo.country length] > 0)
                {
                    [addDict setObject:addressInfo.country  forKey:ADDRESS_KEY_COUNTRY];
                }

                if ([addressInfo.countryCode length] > 0)
                {
                    [addDict setObject:addressInfo.countryCode forKey:ADDRESS_KEY_COUNTRY_CODE];
                }

                if ([addressInfo.state length] > 0)
                {
                    [addDict setObject:addressInfo.state    forKey:ADDRESS_KEY_STATE];
                }

                ABMultiValueAddValueAndLabel(addresses, (__bridge CFTypeRef)(addDict), (__bridge CFStringRef)addressInfo.labelTitle, NULL);
            }
        }

        ABRecordSetValue(self.contactRef, kABPersonAddressProperty, addresses, NULL);
    }
    
    //Portrait
    if (selectedImage == nil)
    {
        ABPersonRemoveImageData(self.contactRef, nil);
    }
    else
    {
        ABPersonSetImageData(self.contactRef, (__bridge CFDataRef)UIImagePNGRepresentation(selectedImage), nil);
    }
    
    //Save the address book
    ABAddressBookRef addressBook = [[NBAddressBookManager sharedManager] getAddressBook];
    if (self.isNewContact)
    {
        ABAddressBookAddRecord(addressBook, self.contactRef, &error);
    }

    ABAddressBookSave(addressBook, &error);
}


- (void)saveNotes:(NSString*)notesString
{
    if (notesString == nil || [notesString length] == 0)
    {
        ABRecordRemoveValue(self.contactRef, kABPersonNoteProperty, nil);
    }
    else
    {
        ABRecordSetValue(self.contactRef, kABPersonNoteProperty, (__bridge CFTypeRef)notesString, NULL);
    }

    ABAddressBookRef addressBook = [[NBAddressBookManager sharedManager] getAddressBook];
    ABAddressBookSave(addressBook, nil);
}


#pragma mark - Support for the label in the list

// The mustFormatNumber parameter was added to make calling the LibPhoneNumber's UIWebView optional
// (indirectly via formatNumber). A UIWebView may only be accessed from the main thread. During
// initial loading, this method is called from another thread; and this would cause the app to crash.
+ (NSString*)getSortingProperty:(ABRecordRef)contactRef mustFormatNumber:(BOOL)mustFormatNumber
{
    //Iterate over the available name properties and find one that exists
    NSMutableArray * arrayWithSortProperties = [NSMutableArray array];
    ABPersonSortOrdering sortOrder = ABPersonGetSortOrdering();
    
    if (sortOrder == kABPersonSortByFirstName)
    {
        [arrayWithSortProperties addObject:[NSNumber numberWithInt:kABPersonFirstNameProperty]];
        [arrayWithSortProperties addObject:[NSNumber numberWithInt:kABPersonFirstNamePhoneticProperty]];
        [arrayWithSortProperties addObject:[NSNumber numberWithInt:kABPersonLastNameProperty]];
        [arrayWithSortProperties addObject:[NSNumber numberWithInt:kABPersonLastNamePhoneticProperty]];
    }
    else
    {
        [arrayWithSortProperties addObject:[NSNumber numberWithInt:kABPersonLastNameProperty]];
        [arrayWithSortProperties addObject:[NSNumber numberWithInt:kABPersonLastNamePhoneticProperty]];
        [arrayWithSortProperties addObject:[NSNumber numberWithInt:kABPersonFirstNameProperty]];
        [arrayWithSortProperties addObject:[NSNumber numberWithInt:kABPersonFirstNamePhoneticProperty]];
    }

    [arrayWithSortProperties addObjectsFromArray:@[[NSNumber numberWithInt:kABPersonNicknameProperty],
                                          [NSNumber numberWithInt:kABPersonOrganizationProperty]]];
    NSString * property = nil;
    for (NSNumber * propertyNum in arrayWithSortProperties)
    {
        ABPropertyID propertyID = (ABPropertyID)[propertyNum intValue];
        property = (__bridge_transfer NSString*)ABRecordCopyValue(contactRef, propertyID);
        
        //If we found a property, break out of the loop
        if (property != nil && [property isKindOfClass:[NSString class]] && [property length] > 0)
        {
            break;
        }
    }

    if (property == nil)
    {
        property = [self getAvailableProperty:kABPersonEmailProperty from:contactRef];
        if (property == nil)
        {
            property = [self getAvailableProperty:kABPersonPhoneProperty from:contactRef];
#ifndef NB_STANDALONE
            if (mustFormatNumber)
            {
                property = [[NBAddressBookManager sharedManager].delegate formatNumber:property];
            }
#endif
        }
    }

    return property;
}


+ (NSString*)getAvailableProperty:(ABPropertyID)property from:(ABRecordRef)contactRef
{
    //If there is no name, check for number or email
    NSString * result = nil;
    
    ABMultiValueRef arrayRef = ABRecordCopyValue(contactRef, property);
    CFIndex arrayCount = ABMultiValueGetCount(arrayRef);
    if (arrayCount > 0)
    {
        for (CFIndex arrayPosition = 0; arrayPosition < arrayCount; arrayPosition++)
        {
            NSString * property = (__bridge NSString*)ABMultiValueCopyValueAtIndex(arrayRef, arrayPosition);
            if (property != nil)
            {
                result = property;
                break;
            }
        }
    }    

    return result;
}


#pragma mark - Single point of handling calls
+ (void)makePhoneCall:(NSString*)phoneNumber
        withContactID:(NSString*)contactID
           completion:(void (^)(BOOL cancelled, CallableData* selectedCallable))completion
{    
#ifndef NB_STANDALONE
    [[CallManager sharedManager] callPhoneNumber:[[PhoneNumber alloc] initWithNumber:phoneNumber]
                                       contactId:contactID
                                      completion:^(Call* call, CallableData* selectedCallable)
    {
        completion ? completion(call == nil, selectedCallable) : (void)0;
    }];
#endif
}

@end
