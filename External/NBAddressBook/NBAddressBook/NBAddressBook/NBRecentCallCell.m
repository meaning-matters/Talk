//
//  NBRecentCallCell.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/20/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "NBRecentCallCell.h"


@implementation NBRecentCallCell

@synthesize numberLabel;
@synthesize numberTypeLabel;
@synthesize callerIdLabel;
@synthesize callerIdImageView;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
    }
    return self;
}

#pragma mark - State transitioning

//Support-method to shift the labels to the right when editing
- (void)shiftLabels:(BOOL)shift
{
    CGRect numberFrame        = numberLabel.frame;
    CGRect numberTypeFrame    = numberTypeLabel.frame;
    CGRect callerIdLabelFrame = callerIdLabel.frame;
    CGRect callerIdImageFrame = callerIdImageView.frame;

    //Determine how to mutate the frame
    if (shift)
    {
        numberFrame.origin.x     = POSITION_NUMBER_LABEL_EDITING;
        numberTypeFrame.origin.x = POSITION_NUMBER_LABEL_EDITING;
        callerIdLabelFrame.origin.x   = POSITION_NUMBER_LABEL_EDITING;
        callerIdImageFrame.origin.x  = POSITION_NUMBER_LABEL_EDITING;
        self.imageView.alpha = 0.0;
    }
    else
    {
        numberFrame.origin.x     = POSITION_NUMBER_LABEL;
        numberTypeFrame.origin.x = POSITION_NUMBER_LABEL;
        callerIdLabelFrame.origin.x   = POSITION_NUMBER_LABEL;
        self.imageView.alpha = 1.0;
    }
    
    numberLabel.frame     = numberFrame;
    numberTypeLabel.frame = numberTypeFrame;
    callerIdLabel.frame   = callerIdLabelFrame;
}

@end
