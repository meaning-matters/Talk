//
//  NBContactStructureManager.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/5/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//
//  Tree-structure representing the tableview of adding/editing a person.
//  First level is the sections, second level are the cells

#import <Foundation/Foundation.h>
#import "NBPersonCellInfo.h"
#import <AddressBook/AddressBook.h>
#import "NBDetailLineSeparatedCell.h"
#import "NBNameTableViewCell.h"
#import "NBContact.h"
#import "NBPersonCellAddressInfo.h"

@interface NBContactStructureManager : NSObject

@property (nonatomic) NSMutableArray * tableStructure;

- (void)reset;
- (void)fillWithContact:(NBContact*)person;
- (void)fillWithContactToMergeWith:(NBContact*)person;
- (NSMutableArray*)getVisibleRows:(BOOL)visible forSection:(NSInteger)sectionIndex;
- (NBPersonCellInfo*)getVisibleCellForIndexPath:(NSIndexPath*)indexPath;
- (void)determineRowVisibility:(BOOL)editing;
- (void)switchIMLabels:(BOOL)editing;
- (NSInteger)removeCellWithTextfield:(UITextField*)textfield;
- (NSInteger)checkToInsertCellBelowCellWithTextfield:(UITextField*)textfield;
- (NSString*)findNextLabelInArray:(NSArray*)array usingSource:(NSMutableArray*)source;
- (NBPersonCellInfo*)getCellInfoForIMLabel:(UILabel*)label;
- (NBPersonCellInfo*)getCellInfoForTextfield:(UITextField*)textfield;
- (NBPersonCellAddressInfo*)getCellInfoForCell:(NBPersonFieldTableCell*)cell inSection:(int)sectionPos;
@end
