//
//  NBPersonIMCell.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/17/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import "NBPersonIMCell.h"

@implementation NBPersonIMCell

@synthesize horiLineView, vertiLineView, typeLabel;

#pragma mark - State transitioning
- (void)willTransitionToState:(UITableViewCellStateMask)state
{
    //Check if we're animating
    BOOL confirmationAnimation = (state & UITableViewCellStateShowingDeleteConfirmationMask) && !isTransitioned;
    BOOL returnAnimation = (state & UITableViewCellStateShowingEditControlMask) && isTransitioned;
    if (confirmationAnimation || returnAnimation)
    {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:ANIMATION_SPEED];
        animationBegun = YES;
    
        if (confirmationAnimation)
        {        
            //Scale the type label
            CGRect typeFrame = self.typeLabel.frame;
            typeFrame.size.width /= 2;
            self.typeLabel.frame = typeFrame;
            
            //Scale the line
            CGRect lineFrame = horiLineView.frame;
            lineFrame.size.width /= 2;
            horiLineView.frame = lineFrame;
        }
        else if (returnAnimation)
        {

            //Scale the type label backs
            CGRect typeFrame = self.typeLabel.frame;
            typeFrame.size.width *= 2;
            self.typeLabel.frame = typeFrame;
            
            //Scale the line back
            CGRect lineFrame = horiLineView.frame;
            lineFrame.size.width *= 2;
            horiLineView.frame = lineFrame;
        }
    }
    //Call the superclass to scale the textfield and flip the boolean
    [super willTransitionToState:state];
}

@end
