//
//  NBPersonFieldTableCell.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/7/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//
//  Extended tableviewcell for the custom Person animations and cell properties

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NBAddressBook.h"

typedef enum
{
    CT_ADD     = 0,
    CT_EDIT    = 1
} CellType;


@interface NBPersonFieldTableCell : UITableViewCell <UIGestureRecognizerDelegate>
{
    //Flag to indicate we scaled the view and subviews to allow for the delete button
    BOOL isTransitioned;
    
    //Flag to indicate animations do not need to begin again
    BOOL animationBegun;
    
    //Remember if our textfield was first responder, to return it to this state later
    BOOL isFirstResponder;
    
    //The original textfield's color, mutated when highlighted
    UIColor * originalTextfieldColor;
}

//The section this cell is in
@property (nonatomic) ContactCell section;

//The label of the cell
@property (nonatomic) UILabel * cellLabel;

//The input
@property (nonatomic) UITextField * cellTextfield;

//The type of cell (add or edit)
@property (nonatomic) CellType cellType;

- (void)mutateTextfieldFrame:(UITextField*)textField half:(BOOL)halfFrame;
- (void)registerForKeyboardDismiss;
@end
