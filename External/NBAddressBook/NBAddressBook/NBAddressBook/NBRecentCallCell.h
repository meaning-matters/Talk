//
//  NBRecentCallCell.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/20/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

#define SIZE_NUMBER_LABEL               200
#define POSITION_NUMBER_LABEL           10
#define POSITION_NUMBER_LABEL_EDITING   40

@interface NBRecentCallCell : UITableViewCell
{
    //Flag to indicate we scaled the view and subviews to allow for the delete button
    BOOL isTransitioned;
    
    //The old imageview center (hard to shift dynamically, as it is based on the variable label's size)
    CGPoint outgoingCallImageViewCenter;
    
    //The original label colors, mutated when highlighted
    UIColor * originalTitleColor;
    UIColor * originalDetailColor;
    
    //Images for outgoing calls
    UIImage * outgoingCallImage;
    UIImage * outgoingCallImageInverted;
}

@property (nonatomic) UILabel * numberLabel;
@property (nonatomic) UILabel * numberTypeLabel;
@property (nonatomic) UIImageView * outgoingCallImageView;

//Animation methods
//- (void)setCellFontsAndImage:(BOOL)selected andDelayed:(BOOL)delayed andAnimated:(BOOL)animated;
- (void)setOutgoingCallImageViewCenter:(CGPoint)center;
- (void)halfLabelFrames:(BOOL)half;
- (void)shiftLabels:(BOOL)shift;

@end
