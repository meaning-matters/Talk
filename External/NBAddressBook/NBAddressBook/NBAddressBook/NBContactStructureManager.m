//
//  NBContactStructureManager.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/5/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "NBContactStructureManager.h"

@implementation NBContactStructureManager

@synthesize tableStructure;

#pragma mark - initialization
- (instancetype)init
{
    if (self = [super init])
    {
        [self constructTree];
    }

    return self;
}


- (void)reset
{
    [self constructTree];
}


#pragma mark - Initialisation
- (void)constructTree
{
    //Build up the table structure
    tableStructure = [NSMutableArray array];
    NSMutableArray * sectionArray;
    for (int section = 0; section < CC_NUMBER_OF_SECTIONS; section++)
    {
        //Each of these arrays holds the info of a cell in the tableview
        sectionArray = [NSMutableArray array];
        switch (section)
        {
            case CC_FILLER:
            {
                //This is merely to push down the cells for the label; an empty filler
                [sectionArray addObject:[[NBPersonCellInfo alloc]initWithPlaceholder:nil andLabel:nil]];
                break;
            }
            case CC_NAME:
            {
                //Has a total of 11 fields
                [sectionArray addObject:[[NBPersonCellInfo alloc]initWithPlaceholder:(__bridge NSString*)ABPersonCopyLocalizedPropertyName(kABPersonPrefixProperty) andLabel:nil]];
                [sectionArray addObject:[[NBPersonCellInfo alloc]initWithPlaceholder:(__bridge NSString*)ABPersonCopyLocalizedPropertyName(kABPersonFirstNameProperty) andLabel:nil]];
                [sectionArray addObject:[[NBPersonCellInfo alloc]initWithPlaceholder:(__bridge NSString*)ABPersonCopyLocalizedPropertyName(kABPersonFirstNamePhoneticProperty) andLabel:nil]];
                [sectionArray addObject:[[NBPersonCellInfo alloc]initWithPlaceholder:(__bridge NSString*)ABPersonCopyLocalizedPropertyName(kABPersonMiddleNameProperty) andLabel:nil]];
                [sectionArray addObject:[[NBPersonCellInfo alloc]initWithPlaceholder:(__bridge NSString*)ABPersonCopyLocalizedPropertyName(kABPersonLastNameProperty) andLabel:nil]];
                [sectionArray addObject:[[NBPersonCellInfo alloc]initWithPlaceholder:(__bridge NSString*)ABPersonCopyLocalizedPropertyName(kABPersonLastNamePhoneticProperty) andLabel:nil]];
                [sectionArray addObject:[[NBPersonCellInfo alloc]initWithPlaceholder:(__bridge NSString*)ABPersonCopyLocalizedPropertyName(kABPersonSuffixProperty) andLabel:nil]];
                [sectionArray addObject:[[NBPersonCellInfo alloc]initWithPlaceholder:(__bridge NSString*)ABPersonCopyLocalizedPropertyName(kABPersonNicknameProperty) andLabel:nil]];
                [sectionArray addObject:[[NBPersonCellInfo alloc]initWithPlaceholder:(__bridge NSString*)ABPersonCopyLocalizedPropertyName(kABPersonJobTitleProperty) andLabel:nil]];
                [sectionArray addObject:[[NBPersonCellInfo alloc]initWithPlaceholder:(__bridge NSString*)ABPersonCopyLocalizedPropertyName(kABPersonDepartmentProperty) andLabel:nil]];
                [sectionArray addObject:[[NBPersonCellInfo alloc]initWithPlaceholder:(__bridge NSString*)ABPersonCopyLocalizedPropertyName(kABPersonOrganizationProperty) andLabel:nil]];
                break;
            }
            case CC_NUMBER:
            {
                //Only show a new-phonenumber cell
                [sectionArray addObject:[[NBPersonCellInfo alloc]initWithPlaceholder:(__bridge NSString *)(ABPersonCopyLocalizedPropertyName(kABPersonPhoneProperty)) andLabel:[[NSString alloc]initWithString:(__bridge NSString*)ABAddressBookCopyLocalizedLabel((__bridge CFStringRef)[NUMBER_ARRAY objectAtIndex:0])]]];
                break;
            }
            case CC_EMAIL:
            {
                [sectionArray addObject:[[NBPersonCellInfo alloc]initWithPlaceholder:(__bridge NSString *)(ABPersonCopyLocalizedPropertyName(kABPersonEmailProperty)) andLabel:(__bridge NSString *)(ABAddressBookCopyLocalizedLabel((__bridge CFStringRef)([HWO_ARRAY objectAtIndex:0])))]];
                break;
            }
            case CC_RINGTONE:
            {
                //The ringtone cell
                NBPersonCellInfo * ringInfo = [[NBPersonCellInfo alloc]initWithPlaceholder:nil andLabel:NSLocalizedString(@"RT_RINGTONE_LABEL", @"")];
                [ringInfo setTextValue:NSLocalizedString(@"RT_DEFAULT", @"")];
                [sectionArray addObject:ringInfo];
                
                //The vibration cell
                NBPersonCellInfo * vibrationInfo = [[NBPersonCellInfo alloc]initWithPlaceholder:nil andLabel:NSLocalizedString(@"RT_VIBRATION_LABEL", @"")];
                [vibrationInfo setTextValue:NSLocalizedString(@"RT_DEFAULT", @"")];
                [sectionArray addObject:vibrationInfo];
                break;
            }
            case CC_HOMEPAGE:
            {
                [sectionArray addObject:[[NBPersonCellInfo alloc]initWithPlaceholder:(__bridge NSString *)(ABPersonCopyLocalizedPropertyName(kABPersonURLProperty)) andLabel:(__bridge NSString *)(ABAddressBookCopyLocalizedLabel((__bridge CFStringRef)([WEB_ARRAY objectAtIndex:0])))]];
                break;
            }
            case CC_ADDRESS:
            {
                NBPersonCellAddressInfo * addressInfo = [[NBPersonCellAddressInfo alloc]initWithPlaceholder:nil andLabel:NSLocalizedString(@"CL_NEW_ADDRESS", @"")];
                [addressInfo setIsAddButton:YES];
                [sectionArray addObject:addressInfo];
                break;
            }
            case CC_BIRTHDAY:
            case CC_OTHER_DATES:
            case CC_RELATED_CONTACTS:
            case CC_SOCIAL:
            case CC_IM:
            case CC_NOTES:
            case CC_CALLER_ID:
            {
                break;
            }
            default:
            {
                break;
            }
        }

        [self.tableStructure addObject:sectionArray];
    }
}

#pragma mark - Setting the existing contact details
- (void)fillWithContact:(NBContact*)person
{
    if (person.contactRef != nil)
    {        
        //Fill the name properties
        NSMutableArray * nameArray = [tableStructure objectAtIndex:CC_NAME];
        for (int nameIndex = 0; nameIndex < [nameArray count]; nameIndex++)
        {
            NSString * personValue;
            switch (nameIndex)
            {
                case NC_PREFIX:
                    personValue = [NBContact getStringProperty:kABPersonPrefixProperty forContact:person.contactRef];
                    break;
                case NC_FIRST_NAME: 
                    personValue = [NBContact getStringProperty:kABPersonFirstNameProperty forContact:person.contactRef];
                    break;
                case NC_PHONETIC_FIRST:
                    personValue = [NBContact getStringProperty:kABPersonFirstNamePhoneticProperty forContact:person.contactRef];
                    break;
                case NC_MIDDLE_NAME:
                    personValue = [NBContact getStringProperty:kABPersonMiddleNameProperty forContact:person.contactRef];
                    break;
                case NC_LAST_NAME: 
                    personValue = [NBContact getStringProperty:kABPersonLastNameProperty forContact:person.contactRef];
                    break;
                case NC_PHONETIC_LAST: 
                    personValue = [NBContact getStringProperty:kABPersonLastNamePhoneticProperty forContact:person.contactRef];
                    break;
                case NC_SUFFIX: 
                    personValue = [NBContact getStringProperty:kABPersonSuffixProperty forContact:person.contactRef];
                    break;
                case NC_NICKNAME: 
                    personValue = [NBContact getStringProperty:kABPersonNicknameProperty forContact:person.contactRef];
                    break;
                case NC_JOB_TITLE: 
                    personValue = [NBContact getStringProperty:kABPersonJobTitleProperty forContact:person.contactRef];
                    break;
                case NC_DEPARTMENT:
                    personValue = [NBContact getStringProperty:kABPersonDepartmentProperty forContact:person.contactRef];
                    break;
                case NC_COMPANY:
                    personValue = [NBContact getStringProperty:kABPersonOrganizationProperty forContact:person.contactRef];
                    break;                
                default:
                    break;
            }
            ((NBPersonCellInfo*)[nameArray objectAtIndex:nameIndex]).textValue = personValue;
        }
        
        //Load in the numbers for this person
        [self loadInDetailPropertiesForArray:[tableStructure objectAtIndex:CC_NUMBER] usingDatasource:ABRecordCopyValue(person.contactRef, kABPersonPhoneProperty) andLabelArray:NUMBER_ARRAY];
        
        //Load in the emails for this person
        [self loadInDetailPropertiesForArray:[tableStructure objectAtIndex:CC_EMAIL] usingDatasource:ABRecordCopyValue(person.contactRef, kABPersonEmailProperty) andLabelArray:HWO_ARRAY];
        
        //Load in the URLs for this person
        [self loadInDetailPropertiesForArray:[tableStructure objectAtIndex:CC_HOMEPAGE] usingDatasource:ABRecordCopyValue(person.contactRef, kABPersonURLProperty) andLabelArray:WEB_ARRAY];
        
        //Load in the birthday
        NSDate * dateBirthday = (NSDate*) CFBridgingRelease(ABRecordCopyValue(person.contactRef, kABPersonBirthdayProperty));
        if (dateBirthday != nil)
        {
            //Insert a date cell
            NSMutableArray * sectionArray = [self.tableStructure objectAtIndex:CC_BIRTHDAY];
            NBPersonCellInfo * cellInfo = [[NBPersonCellInfo alloc]initWithPlaceholder:nil andLabel:(__bridge NSString *)(ABPersonCopyLocalizedPropertyName(kABPersonBirthdayProperty))];
            [cellInfo setDateValue:dateBirthday];
            [sectionArray addObject:cellInfo];
        }
        
        //Load in the other dates
        NSMutableArray * targetDatesArray = [tableStructure objectAtIndex:CC_OTHER_DATES];
        ABMultiValueRef datesRef = ABRecordCopyValue(person.contactRef, kABPersonDateProperty);
        if (datesRef != nil)
        {
            CFIndex numDates = ABMultiValueGetCount(datesRef);
            for (CFIndex i = 0; i < numDates; i++)
            {
                NSString* label = (__bridge NSString *)ABAddressBookCopyLocalizedLabel((ABMultiValueCopyLabelAtIndex(datesRef, i)));
                NSDate* date = (__bridge NSDate *)(ABMultiValueCopyValueAtIndex(datesRef, i));
                
                //Create a new cell for each entry
                NBPersonCellInfo * personCellInfo = [[NBPersonCellInfo alloc] initWithPlaceholder:(__bridge NSString *)(ABPersonCopyLocalizedPropertyName(kABPersonDateProperty)) andLabel:label];
                [personCellInfo setDateValue:date];
                [targetDatesArray addObject:personCellInfo];
            }
            if (numDates > 0)
            {
                [targetDatesArray addObject:[[NBPersonCellInfo alloc]initWithPlaceholder:(__bridge NSString *)(ABPersonCopyLocalizedPropertyName(kABPersonDateProperty)) andLabel:(__bridge NSString *)(ABAddressBookCopyLocalizedLabel(kABOtherLabel))]];
            }
        }

        //Load in the related contacts
        NSMutableArray * relatedArray = [tableStructure objectAtIndex:CC_RELATED_CONTACTS];
        [self loadInDetailPropertiesForArray:relatedArray usingDatasource:ABRecordCopyValue(person.contactRef, kABPersonRelatedNamesProperty) andLabelArray:RELATED_ARRAY];
        if ([relatedArray count] > 0)
        {
            //If we have info, enter a new-cell
            NBPersonCellInfo * cellInfo = [[NBPersonCellInfo alloc]initWithPlaceholder:NSLocalizedString(@"PH_NAME", @"") andLabel:NSLocalizedString([self findNextLabelInArray:RELATED_ARRAY usingSource:relatedArray], @"")];
            [relatedArray addObject:cellInfo];
        }
        
        //Load in the notes
        NSString * notes = [NBContact getStringProperty:kABPersonNoteProperty forContact:person.contactRef];
        if (notes != nil)
        {
            NSMutableArray * sectionArray = [self.tableStructure objectAtIndex:CC_NOTES];
            NBPersonCellInfo * cellInfo = [[NBPersonCellInfo alloc]initWithPlaceholder:nil andLabel:(__bridge NSString *)(ABPersonCopyLocalizedPropertyName(kABPersonNoteProperty))];
            [cellInfo setTextValue:notes];
            [sectionArray addObject:cellInfo];
        }
        
        {
            NSMutableArray* sectionArray = [self.tableStructure objectAtIndex:CC_CALLER_ID];
            NSString*       contactId    = [NSString stringWithFormat:@"%d", ABRecordGetRecordID(person.contactRef)];
            NSString*       placeholder;
            
            if ([[NBAddressBookManager sharedManager].delegate callerIdIsShownForContactId:contactId])
            {
                placeholder = NSLocalizedString(@"CI_USES_DEFAULT", @"");
            }
            else
            {
                placeholder = NSLocalizedString(@"CI_IS_NOT_SHOWN", @"");
            }
            
            NBPersonCellInfo* personCellInfo = [[NBPersonCellInfo alloc] initWithPlaceholder:placeholder
                                                                                    andLabel:NSLocalizedString(@"CI_CALLER_ID", @"")];
            NSString* callerIdName = [[NBAddressBookManager sharedManager].delegate callerIdNameForContactId:contactId];
            [personCellInfo setTextValue:callerIdName];
            [sectionArray addObject:personCellInfo];
        }
        
        //Load in the IM
        NSMutableArray * IMArray = [self.tableStructure objectAtIndex:CC_IM];
        ABMultiValueRef instantMessageRef = ABRecordCopyValue(person.contactRef, kABPersonInstantMessageProperty);
        CFIndex numIMs = ABMultiValueGetCount(instantMessageRef);
        for (CFIndex i = 0; i < numIMs; i++)
        {
            NSString* label = (__bridge NSString *)ABAddressBookCopyLocalizedLabel((ABMultiValueCopyLabelAtIndex(instantMessageRef, i)));
            NSDictionary * contentDictionary = (__bridge NSDictionary*)ABMultiValueCopyValueAtIndex(instantMessageRef, i);
            
            //Create a new cell for each entry
            NBPersonCellInfo * personCellInfo = [[NBPersonCellInfo alloc] initWithPlaceholder:(__bridge NSString *)(ABAddressBookCopyLocalizedLabel(kABPersonInstantMessageUsernameKey)) andLabel:label];
            [personCellInfo setIMType:[contentDictionary objectForKey:KEY_SERVICE]];
            [personCellInfo setTextValue:[contentDictionary objectForKey:KEY_USERNAME]];
            [IMArray addObject:personCellInfo];
        }
        if (numIMs > 0)
        {
            NBPersonCellInfo * newCellInfo = [[NBPersonCellInfo alloc]initWithPlaceholder:(__bridge NSString *)(ABAddressBookCopyLocalizedLabel(kABPersonInstantMessageUsernameKey)) andLabel:(__bridge NSString *)(ABAddressBookCopyLocalizedLabel(kABHomeLabel))];
            [newCellInfo setIMType:(__bridge NSString*)ABAddressBookCopyLocalizedLabel((__bridge CFStringRef)[IM_ARRAY objectAtIndex:0])];
            [IMArray addObject:newCellInfo];
        }
        
        //Load in the Social
        NSMutableArray * socialArray = [self.tableStructure objectAtIndex:CC_SOCIAL];
        ABMultiValueRef socialMessageRef = ABRecordCopyValue(person.contactRef, kABPersonSocialProfileProperty);
        CFIndex numSocial = ABMultiValueGetCount(socialMessageRef);
        for (CFIndex i = 0; i < numSocial; i++)
        {
            NSDictionary * socialDictionary = (__bridge NSDictionary *)(ABMultiValueCopyValueAtIndex(socialMessageRef, i));

            //Create a new cell for each entry
            NBPersonCellInfo * personCellInfo = [[NBPersonCellInfo alloc] initWithPlaceholder:(__bridge NSString *)(ABAddressBookCopyLocalizedLabel(kABPersonInstantMessageUsernameKey)) andLabel:[socialDictionary objectForKey:KEY_SERVICE]];
            [personCellInfo setTextValue:[socialDictionary objectForKey:KEY_USERNAME]];
            [socialArray addObject:personCellInfo];
        }
        if (numSocial > 0)
        {
            NBPersonCellInfo * newSocialCellinfo = [[NBPersonCellInfo alloc]initWithPlaceholder:(__bridge NSString *)(ABAddressBookCopyLocalizedLabel(kABPersonInstantMessageUsernameKey)) andLabel:(__bridge NSString *)(ABAddressBookCopyLocalizedLabel(kABHomeLabel))];
            [socialArray addObject:newSocialCellinfo];
        }
        
        //Load in the addresses
        NSMutableArray * addressArray = [self.tableStructure objectAtIndex:CC_ADDRESS];
        ABMultiValueRef addressRef = ABRecordCopyValue(person.contactRef, kABPersonAddressProperty);
        NBPersonCellAddressInfo * addInfo = [addressArray lastObject];
        [addressArray removeLastObject];
        for (CFIndex i = 0; i < ABMultiValueGetCount(addressRef); i++)
        {
            NSString* label = (__bridge NSString *)ABAddressBookCopyLocalizedLabel((ABMultiValueCopyLabelAtIndex(addressRef, i)));   
            NSDictionary * addDictionary = (__bridge NSDictionary *)(ABMultiValueCopyValueAtIndex(addressRef, i));
            
            //Create a new cell for each entry
            NBPersonCellAddressInfo * addressCellInfo = [[NBPersonCellAddressInfo alloc] initWithPlaceholder:nil andLabel:label];
            
            //Set all the cell info
            [addressCellInfo.streetLines addObjectsFromArray:[[addDictionary objectForKey:ADDRESS_KEY_STREET] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]];

            //City
            [addressCellInfo setCity:[addDictionary objectForKey:ADDRESS_KEY_CITY]];
            
            //Country
            [addressCellInfo setCountry:[addDictionary objectForKey:ADDRESS_KEY_COUNTRY]];
            
            //ZIP
            [addressCellInfo setZIP:[addDictionary objectForKey:ADDRESS_KEY_ZIP]];
            
            //State
            [addressCellInfo setState:[addDictionary objectForKey:ADDRESS_KEY_STATE]];
            
            //Country Code
            [addressCellInfo setCountryCode:[[addDictionary objectForKey:ADDRESS_KEY_COUNTRY_CODE] uppercaseString]];
            
            //Add the street
            [addressArray addObject:addressCellInfo];
        }
        [addressArray addObject:addInfo];
        
        //Load in the portrait
        [person setImage:[person getImage:YES]];
    }
}

#pragma mark - Setting the phone number to merge with
- (void)fillWithContactToMergeWith:(NBContact*)person
{
    //Add a new entry in the number-field
    NSString * number = [NBContact getAvailableProperty:kABPersonPhoneProperty from:person.contactRef];
#ifndef NB_STANDALONE
    number = [[NBAddressBookManager sharedManager].delegate formatNumber:number];
#endif
    if ([number length] > 0)
    {
        NSMutableArray * section = [tableStructure objectAtIndex:CC_NUMBER];
        NSString * firstAvailableLabel = [self findNextLabelInArray:NUMBER_ARRAY usingSource:section];
        NBPersonCellInfo * mergedInfo = [[NBPersonCellInfo alloc]initWithPlaceholder:(__bridge NSString *)(ABPersonCopyLocalizedPropertyName(kABPersonPhoneProperty)) andLabel:NSLocalizedString(firstAvailableLabel, @"")];
        [mergedInfo setTextValue:number];
        [mergedInfo setIsMergedField:YES];
        [section insertObject:mergedInfo atIndex:[section count] - 1];
    }
    
    //Merge e-mail if we have one
    NSString * email = [NBContact getAvailableProperty:kABPersonEmailProperty from:person.contactRef];
    if ([email length] > 0)
    {
        NSMutableArray * section = [tableStructure objectAtIndex:CC_EMAIL];
        NSString * firstAvailableLabel = [self findNextLabelInArray:HWO_ARRAY usingSource:section];
        NBPersonCellInfo * mergedInfo = [[NBPersonCellInfo alloc]initWithPlaceholder:(__bridge NSString *)(ABPersonCopyLocalizedPropertyName(kABPersonPhoneProperty)) andLabel:NSLocalizedString(firstAvailableLabel, @"")];
        [mergedInfo setTextValue:email];
        [mergedInfo setIsMergedField:YES];
        [section insertObject:mergedInfo atIndex:[section count] - 1];
    }
}

- (void)loadInDetailPropertiesForArray:(NSMutableArray*)targetArray usingDatasource:(ABMultiValueRef)source andLabelArray:(NSArray*)labelArray
{
    //Fill all numbers and the section representing the numbers
    NBPersonCellInfo * newNumberCellInfo = [targetArray lastObject];
    [targetArray removeLastObject];
    for (CFIndex i = 0; i < ABMultiValueGetCount(source); i++)
    {        
        NSString* label = (__bridge NSString *)ABAddressBookCopyLocalizedLabel((ABMultiValueCopyLabelAtIndex(source, i)));
        NSString* value = (__bridge NSString *)(ABMultiValueCopyValueAtIndex(source, i));
        
        //Create a new cell for each entry
        NBPersonCellInfo * personCellInfo = [[NBPersonCellInfo alloc] initWithPlaceholder:(__bridge NSString *)(ABPersonCopyLocalizedPropertyName(kABPersonPhoneProperty)) andLabel:label];
        [personCellInfo setTextValue:value];
        [targetArray addObject:personCellInfo];
    }
    //Finally, add the last object representing the new-number cell, updating the label to the next available one
    NSString * newLabel = [self findNextLabelInArray:labelArray usingSource:targetArray];
    [newNumberCellInfo setLabelTitle:newLabel];
    if (newNumberCellInfo != nil)
        [targetArray addObject:newNumberCellInfo];
}

#pragma mark - Visibility changes when editing
- (void)determineRowVisibility:(BOOL)editing
{
    //Mutate the line and textfield of the detail cells
    NSArray * editableArrays = [[[[[[[tableStructure objectAtIndex:CC_NUMBER]
                                arrayByAddingObjectsFromArray:[tableStructure objectAtIndex:CC_EMAIL]]
                                arrayByAddingObjectsFromArray:[tableStructure objectAtIndex:CC_HOMEPAGE]]
                                arrayByAddingObjectsFromArray:[tableStructure objectAtIndex:CC_RELATED_CONTACTS]]
                                arrayByAddingObjectsFromArray:[tableStructure objectAtIndex:CC_NOTES]]
                                arrayByAddingObjectsFromArray:[tableStructure objectAtIndex:CC_SOCIAL]]
                                arrayByAddingObjectsFromArray:[tableStructure objectAtIndex:CC_ADDRESS]];
    for (NBPersonCellInfo * cellInfo in editableArrays)
    {
        NBDetailLineSeparatedCell * detailCell = [cellInfo getDetailCell];
        [detailCell.cellTextfield setEnabled:editing];
        [detailCell.lineView setHidden:!editing];
    }
    
    //Mutate the textfields of editable cells (email, homepage, related, IM and social)
    NSArray * textfieldArrays = [[[[[[tableStructure objectAtIndex:CC_NUMBER]
                                arrayByAddingObjectsFromArray:[tableStructure objectAtIndex:CC_EMAIL]]
                                arrayByAddingObjectsFromArray:[tableStructure objectAtIndex:CC_HOMEPAGE]]
                                arrayByAddingObjectsFromArray:[tableStructure objectAtIndex:CC_RELATED_CONTACTS]]
                                arrayByAddingObjectsFromArray:[tableStructure objectAtIndex:CC_IM]]
                                arrayByAddingObjectsFromArray:[tableStructure objectAtIndex:CC_SOCIAL]];
    for (NBPersonCellInfo * cellInfo in textfieldArrays)
    {
        NBPersonFieldTableCell * detailCell = [cellInfo getPersonFieldTableCell];
        CGRect frame = detailCell.cellTextfield.frame;
        frame.size.width = SIZE_TEXTVIEW_WIDTH;
        [detailCell.cellTextfield setFrame:frame];
    }
    
    //Don't enable the textfields of dates
    NSArray * dateArrays = [[tableStructure objectAtIndex:CC_OTHER_DATES] arrayByAddingObjectsFromArray:[tableStructure objectAtIndex:CC_BIRTHDAY]];
    for (NBPersonCellInfo * cellInfo in dateArrays)
    {
        NBDetailLineSeparatedCell * detailCell = [cellInfo getDetailCell];
        [detailCell.lineView setHidden:!editing];
    }
    
    //Handle the address cell's add-button separately
    [[[tableStructure objectAtIndex:CC_ADDRESS] lastObject] setVisible:editing];
    
    //Handle the IM seperately, since their structure is different
    NSArray * IMArray = [tableStructure objectAtIndex:CC_IM];
    for (NBPersonCellInfo * cellInfo in IMArray)
    {
        NBPersonIMCell * imCell = [cellInfo getIMCell];
        //Hide the horizontal, vertical line and editing field in view-mode
        [imCell.cellTextfield setEnabled:editing];
        [imCell.typeLabel setHidden:!editing];
        [imCell.vertiLineView setHidden:!editing];
        [imCell.horiLineView setHidden:!editing];
    }
    
    //If we have notes, always enable them
    NSArray * notesArray = [tableStructure objectAtIndex:CC_NOTES];
    if ([notesArray count] > 0)
    {
        NBPersonCellInfo * cellInfo = [notesArray objectAtIndex:0];
        [[cellInfo getNotesCell].cellTextview setUserInteractionEnabled:YES];
    }
    
    //Mutate the sections in general
    for (int section = 0; section < [tableStructure count]; section++)
    {
        NSMutableArray * sectionArray = [tableStructure objectAtIndex:section];
        switch (section) {
            case CC_NAME:
            {
                //Always show the first name, last name and company
                [[sectionArray objectAtIndex:NC_FIRST_NAME] setVisible:editing];
                [[sectionArray objectAtIndex:NC_LAST_NAME] setVisible:editing];
                [[sectionArray objectAtIndex:NC_COMPANY] setVisible:editing];
                
                //Also show any fields that have text in them
                for (int i = 0; i < [sectionArray count]; i++)
                {
                    //Skip these cells
                    if (i != NC_FIRST_NAME && i != NC_LAST_NAME && i != NC_COMPANY)
                    {
                        NBPersonCellInfo * cellInfo = [sectionArray objectAtIndex:i];
                        [cellInfo setVisible:[[cellInfo textValue] length] > 0];
                    }
                }
            }
                break;
            case CC_NUMBER:
            {
                //Show all cells that have content
                for (int i = 0; i < [sectionArray count]; i++)
                {
                    NBPersonCellInfo * cellInfo = [sectionArray objectAtIndex:i];
                    [cellInfo setVisible:[cellInfo textValue] > 0];
                }
                
                //If we're editing, also show the last cell, which is an adding-number cell
                [[sectionArray lastObject] setVisible:editing];
            }
                break;
            case CC_EMAIL:
            case CC_HOMEPAGE:
            case CC_SOCIAL:
            case CC_IM:
            case CC_RELATED_CONTACTS:
            {
                //Always let the last cell be the first entry
                for (NBPersonCellInfo * cellInfo in sectionArray)
                {
                    [cellInfo setVisible:[[cellInfo textValue] length] > 0];
                }
                
                //Always make sure the last cell is a new line when editing
                [[sectionArray lastObject] setVisible:editing];
            }
                break;
            case CC_NOTES:
            {
                if ([sectionArray count] > 0)
                {
                    NBPersonCellInfo * notesInfo = [sectionArray lastObject];
                    [notesInfo setVisible:([notesInfo.textValue length] > 0) || editing];
                }
            }
                break;
            default:
                break;
        }
    }
}

#pragma mark - Merge IM labels when not editing
- (void)switchIMLabels:(BOOL)editing
{
    NSArray * imInfo = [tableStructure objectAtIndex:CC_IM];
    for (NBPersonCellInfo * cellInfo in imInfo)
    {
        if ([cellInfo.IMType length] > 0)
        {
            NSString * typeToAppend = [NSString stringWithFormat:@" (%@)", cellInfo.IMType];
            NSString * labelText = cellInfo.textValue;
            if ([labelText length] > 0)
            {
                NSRange typeIndex = [labelText rangeOfString:typeToAppend];
                
                //If editing, chop off the type
                if (editing && typeIndex.location != NSNotFound)
                {
                    cellInfo.textValue = [cellInfo.textValue substringToIndex:typeIndex.location];
                    [[cellInfo getIMCell].cellTextfield setText:cellInfo.textValue];
                }
                //If not editing, append the type
                else if (!editing && typeIndex.location == NSNotFound)
                {
                    cellInfo.textValue = [NSString stringWithFormat:@"%@%@", cellInfo.textValue, typeToAppend];
                    [[cellInfo getIMCell].cellTextfield setText:cellInfo.textValue];
                }
            }
        }
    }
}

#pragma mark - Array of all rows of given visibility in this section
- (NSMutableArray*)getVisibleRows:(BOOL)visible forSection:(NSInteger)sectionIndex
{
    //Skip ringtones for now
    if( sectionIndex == CC_RINGTONE )
    {
#ifndef NB_HAS_RING_TONES
        return 0;
#endif
    }
    
    NSMutableArray * rows = [NSMutableArray array];
    NSMutableArray * section = [self.tableStructure objectAtIndex:sectionIndex];
    for (NBPersonCellInfo * personCellInfo in section)
    {
        if (( personCellInfo.visible && visible) || ( !personCellInfo.visible && !visible))
        {
               [rows addObject:personCellInfo];
        }
    }
    
    return rows;
}

#pragma mark - Get the corresponding visible cell info
- (NBPersonCellInfo*)getVisibleCellForIndexPath:(NSIndexPath*)indexPath
{
    //Find the Nth visible row
    int nthVisibleCell = 0;
    NBPersonCellInfo * visibleCellInfo = nil;
    NSMutableArray * tableSection = [tableStructure objectAtIndex:indexPath.section];
    for (NBPersonCellInfo * personCellInfo in tableSection)
    {
        //Count down for each encountered visible cell
        if (personCellInfo.visible && nthVisibleCell == indexPath.row)
        {
            visibleCellInfo = personCellInfo;
            break;
        }
        else if (personCellInfo.visible)
        {
            nthVisibleCell++;
        }
    }
    return visibleCellInfo;
}

#pragma mark - Removing/inserting cells from model through textfield
//Support function to remove this cell when it is empty (only used for detail cells)
- (NSInteger)removeCellWithTextfield:(UITextField*)textfield
{
    NSMutableArray * section = [tableStructure objectAtIndex:textfield.tag];
    //Only if there are more cells and this textfield is empty, can we delete
    if ([section count] > 1 && [textfield.text length] == 0)
    {
        //Find the cell this textfield belongs to
        for (NBPersonCellInfo * cellInfo in section)
        {
            //If this cell is not the last one
            if ([cellInfo getDetailCell].cellTextfield == textfield)
            {
                if ([section lastObject] != cellInfo)
                {
                    NSUInteger cellPosition = [section indexOfObject:cellInfo];
                    [section removeObject:cellInfo];
                    return cellPosition;
                }
                else
                {
                    break;
                }
            }
        }
    }

    // No cell removed
    return -1;
}

//Support function to make cells appear below this one when typing something in this cell (only used for Detail line separated cells)
- (NSInteger)checkToInsertCellBelowCellWithTextfield:(UITextField*)textfield
{
    NSMutableArray * section = [tableStructure objectAtIndex:textfield.tag];
    NBPersonCellInfo * lastCellInfo = [section lastObject];
    
    NBPersonCellInfo * newCellInfo = [[NBPersonCellInfo alloc]init];
    if ([lastCellInfo getDetailCell].cellTextfield == textfield)
    {
        NSString * placeHolder;
        NSString * label;
        switch (textfield.tag)
        {
            case CC_NUMBER:
            {
                placeHolder = (__bridge NSString *)(ABPersonCopyLocalizedPropertyName(kABPersonPhoneProperty));
                label = [self findNextLabelInArray:NUMBER_ARRAY usingSource:section];
            }
                break;
            case CC_EMAIL:
            {
                placeHolder = (__bridge NSString *)(ABPersonCopyLocalizedPropertyName(kABPersonEmailProperty));
                label = [self findNextLabelInArray:HWO_ARRAY usingSource:section];
            }
                break;
            case CC_HOMEPAGE:
            {
                placeHolder = (__bridge NSString *)(ABPersonCopyLocalizedPropertyName(kABPersonURLProperty));
                label = [self findNextLabelInArray:WEB_ARRAY usingSource:section];
            }
                break;
            case CC_SOCIAL:
            {
                placeHolder = (__bridge NSString *)(ABAddressBookCopyLocalizedLabel(kABPersonInstantMessageUsernameKey));
                label = [self findNextLabelInArray:SOCIAL_ARRAY usingSource:section];
            }
                break;
            case CC_IM:
            {
                placeHolder = (__bridge NSString *)(ABAddressBookCopyLocalizedLabel(kABPersonInstantMessageUsernameKey));
                label = [self findNextLabelInArray:HWO_ARRAY usingSource:section];
                [newCellInfo setIMType:[IM_ARRAY objectAtIndex:0]];
            }
                break;
            case CC_RELATED_CONTACTS:
            {
                placeHolder = NSLocalizedString(@"PH_NAME", @"");
                label = [self findNextLabelInArray:RELATED_ARRAY usingSource:section];
            }
                break;
            default:
                break;
        }
        //Set the shared properties
        [newCellInfo setTextfieldPlaceHolder:placeHolder];
        [newCellInfo setLabelTitle:label];
        [newCellInfo setVisible:YES];
        
        [section addObject:newCellInfo];
        [[section lastObject] setVisible:YES];
        return [section indexOfObject:lastCellInfo] + 1;
    }

    //No cell inserted
    return -1;
}

#pragma mark - Quick lookup for a cell based on properties
- (NBPersonCellInfo*)getCellInfoForTextfield:(UITextField*)textfield
{
    //Find the cell this textfield belongs to
    NSMutableArray * section = [tableStructure objectAtIndex:textfield.tag];
    for (NBPersonCellInfo * cellInfo in section)
    {
        //If this cell is not the last one
        if ([cellInfo getPersonFieldTableCell].cellTextfield == textfield)
        {
            return cellInfo;
        }
    }
    return nil;
}

- (NBPersonCellAddressInfo*)getCellInfoForCell:(NBPersonFieldTableCell*)cell inSection:(int)sectionPos
{
    //Find the cell this cell belongs to
    NSMutableArray * section = [tableStructure objectAtIndex:sectionPos];
    for (NBPersonCellAddressInfo * cellInfo in section)
    {
        //If this cell is not the last one
        if ([cellInfo getPersonFieldTableCell] == cell)
        {
            return cellInfo;
        }
    }
    return nil;
}


- (NBPersonCellInfo*)getCellInfoForIMLabel:(UILabel*)label
{
    //Find the cell this IM belongs to
    NSMutableArray * section = [tableStructure objectAtIndex:CC_IM];
    for (NBPersonCellInfo * cellInfo in section)
    {
        //If this cell is not the last one
        if ([cellInfo getIMCell].typeLabel == label)
        {
            return cellInfo;
        }
    }

    return nil;
}


#pragma mark - Search for the next unused label
- (NSString*)findNextLabelInArray:(NSArray*)array usingSource:(NSMutableArray*)source
{
    //Find the first label in the array that isn't used in source. Else, use the last label
    NSString * labelToUse = (__bridge NSString*)ABAddressBookCopyLocalizedLabel((__bridge CFStringRef)[array lastObject]);
    for (NSString * labelRef in array)
    {
        NSString * translatedLabel = (__bridge NSString*)ABAddressBookCopyLocalizedLabel((__bridge CFStringRef)labelRef);
        
        BOOL labelFound = NO;
        for (NBPersonCellInfo * cellInfo in source)
        {
            //Make sure to compare the translated version (which the existing cell is already using)
            if ([cellInfo.labelTitle isEqualToString:translatedLabel])
            {
                labelFound = YES;
                break;
            }
        }
        if (!labelFound)
        {
            labelToUse = translatedLabel;
            break;
        }
    }
    return labelToUse;
}
@end
