//
//  NBRecentCallCell.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/20/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define SIZE_NUMBER_LABEL               200
#define POSITION_NUMBER_LABEL           40
#define POSITION_NUMBER_LABEL_EDITING   53


@interface NBRecentCallCell : UITableViewCell
{
    //Flag to indicate we scaled the view and subviews to allow for the delete button
    BOOL isTransitioned;
        
    //The original label colors, mutated when highlighted
    UIColor* originalTitleColor;
    UIColor* originalDetailColor;
}

@property (nonatomic) UILabel* numberLabel;
@property (nonatomic) UILabel* numberTypeLabel;

//Animation methods
//- (void)setCellFontsAndImage:(BOOL)selected andDelayed:(BOOL)delayed andAnimated:(BOOL)animated;
- (void)halfLabelFrames:(BOOL)half;
- (void)shiftLabels:(BOOL)shift;

@end
