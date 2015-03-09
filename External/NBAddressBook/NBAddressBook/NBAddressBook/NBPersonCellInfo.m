//
//  NBPersonCellInfo.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/5/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import "NBPersonCellInfo.h"

@implementation NBPersonCellInfo

@synthesize visible, labelTitle, textfieldPlaceHolder, textValue, tableViewCell, isMergedField, IMType, dateValue, makeFirstResponder;

- (instancetype)initWithPlaceholder:(NSString*)placeHolderParam andLabel:(NSString*)labelTitleParam
{
    if (self = [super init])
    {
        textfieldPlaceHolder = placeHolderParam;
        labelTitle = labelTitleParam;
        
        //Show the cell by default
        visible = YES;
    }
    return self;
}

#pragma mark - Support methods for quick cell retrieval
//Get the general person's cell with textfield and label
- (NBPersonFieldTableCell*)getPersonFieldTableCell
{
    return (NBPersonFieldTableCell*)self.tableViewCell;
}

//Cell specialised for name-fields
- (NBNameTableViewCell*)getNameTableViewCell
{
    return (NBNameTableViewCell*)tableViewCell;
}

//Cell specialised for detail-fields (website, numbers, email)
- (NBDetailLineSeparatedCell*)getDetailCell
{
    return (NBDetailLineSeparatedCell*)tableViewCell;
}

//Cell specialised for address fields
- (NBAddressCell*)getAddressCell
{
    return (NBAddressCell*)tableViewCell;
}

//Cell specialised for notes fields
- (NBNotesCell*)getNotesCell
{
    return (NBNotesCell*)tableViewCell;
}

//Cell specialised for date fields
- (NBDateCell*)getDateCell
{
    return (NBDateCell*)tableViewCell;
}

//Cell specialised for IM fields
- (NBPersonIMCell*)getIMCell
{
    return (NBPersonIMCell*)tableViewCell;
}

@end
