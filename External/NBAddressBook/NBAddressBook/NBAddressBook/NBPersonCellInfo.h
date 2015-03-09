//
//  NBPersonCellInfo.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/5/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//
//  Meta-information of a person's table view cells, used to hide/show in edit mode

#import <Foundation/Foundation.h>
#import "NBNameTableViewCell.h"
#import "NBDetailLineSeparatedCell.h"
#import "NBAddressCell.h"
#import "NBNotesCell.h"
#import "NBDateCell.h"
#import "NBPersonIMCell.h"

@interface NBPersonCellInfo : NSObject

//Flag to indicate this cell needs focus as soon as it becomes visible
@property (nonatomic) BOOL makeFirstResponder;

//Indicate wether this cell should be visible
@property (nonatomic) BOOL visible;

//Flag to indicate this field was merged from another contact (in order to color the font)
@property (nonatomic) BOOL isMergedField;

//The title of the optional label in the cell
@property (nonatomic) NSString * labelTitle;

//The placeholder for the optional textfield
@property (nonatomic) NSString * textfieldPlaceHolder;

//The inputted & to be set text value for the textfield
@property (nonatomic) NSString * textValue;

//Selected date
@property (nonatomic) NSDate * dateValue;

//The cached tableview cell
@property (nonatomic) UITableViewCell * tableViewCell;

//The type of IM
@property (nonatomic) NSString * IMType;

- (instancetype)initWithPlaceholder:(NSString*)placeHolderParam andLabel:(NSString*)labelTitle;
- (NBPersonFieldTableCell*)getPersonFieldTableCell;
- (NBNameTableViewCell*)getNameTableViewCell;
- (NBDetailLineSeparatedCell*)getDetailCell;
- (NBAddressCell*)getAddressCell;
- (NBNotesCell*)getNotesCell;
- (NBDateCell*)getDateCell;
- (NBPersonIMCell*)getIMCell;
@end
