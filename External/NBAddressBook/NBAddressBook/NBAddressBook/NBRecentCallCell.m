//
//  NBRecentCallCell.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/20/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "NBRecentCallCell.h"

@implementation NBRecentCallCell

@synthesize numberLabel, numberTypeLabel, outgoingCallImageView;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
        outgoingCallImage = [UIImage imageNamed:@"outgoingCall"];
        outgoingCallImageInverted = [UIImage imageNamed:@"outgoingCall"];
    }
    return self;
}

#pragma mark - State transitioning
//Scale back the fields to allow for the delete-button
- (void)willTransitionToState:(UITableViewCellStateMask)state
{
    //Check if we're animating
    BOOL confirmationAnimation = (state & UITableViewCellStateShowingDeleteConfirmationMask) && !isTransitioned;
    BOOL returnAnimation = (state & UITableViewCellStateShowingEditControlMask) && isTransitioned;
    if (confirmationAnimation || returnAnimation)
    {
        //If we go from edit to delete-confirmation
        if (confirmationAnimation)
        {
            isTransitioned = YES;
            
            //Cut the frame of the number and numbertype in half
            [self halfLabelFrames:YES];
        }
        //If we go back from delete-confirmation to edit
        else if (returnAnimation)
        {
            isTransitioned = NO;
            
            //Restore the labels
            [self halfLabelFrames:NO];
        }
    }
    [super willTransitionToState:state];
}

#pragma mark - Animation support
//Support method to collapse the frames of the labels in this cell
- (void)halfLabelFrames:(BOOL)half
{
    CGRect numberFrame = numberLabel.frame;
    CGRect numberTypeFrame = numberTypeLabel.frame;
    
    //Determine how to mutate the frame
    if (half)
    {
        numberFrame.size.width      = SIZE_NUMBER_LABEL / 1.5f;
        numberTypeFrame.size.width  = SIZE_NUMBER_LABEL / 1.5f;
    }
    else
    {
        numberFrame.size.width      = SIZE_NUMBER_LABEL;
        numberTypeFrame.size.width  = SIZE_NUMBER_LABEL;
    }
    
    numberLabel.frame = numberFrame;
    numberTypeLabel.frame = numberTypeFrame;
}

- (void)setOutgoingCallImageViewCenter:(CGPoint)center
{
    outgoingCallImageViewCenter = center;
    outgoingCallImageView.center= outgoingCallImageViewCenter;
}

//Support-method to shift the labels to the right when editing
- (void)shiftLabels:(BOOL)shift
{
    CGRect numberFrame = numberLabel.frame;
    CGRect numberTypeFrame = numberTypeLabel.frame;
    
    //Determine how to mutate the frame
    if (shift)
    {
        numberFrame.origin.x            = POSITION_NUMBER_LABEL_EDITING;
        numberTypeFrame.origin.x        = POSITION_NUMBER_LABEL_EDITING;
        outgoingCallImageView.center    = CGPointMake( outgoingCallImageViewCenter.x + 30, outgoingCallImageViewCenter.y);
    }
    else
    {
        numberFrame.origin.x            = POSITION_NUMBER_LABEL;
        numberTypeFrame.origin.x        = POSITION_NUMBER_LABEL;
        outgoingCallImageView.center    = outgoingCallImageViewCenter;
    }
    
    numberLabel.frame           = numberFrame;
    numberTypeLabel.frame       = numberTypeFrame;
}

@end
