//
//  NBNotesCell.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/12/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "NBNotesCell.h"

@implementation NBNotesCell

@synthesize cellTextview;

#pragma mark - State transitioning
//Scale back the fields to allow for the delete-button
- (void)willTransitionToState:(UITableViewCellStateMask)state
{
    //Check if we're animating
    BOOL confirmationAnimation = (state & UITableViewCellStateShowingDeleteConfirmationMask) && !isTransitioned;
    BOOL returnAnimation = (state & UITableViewCellStateShowingEditControlMask) && isTransitioned;
    if (confirmationAnimation || returnAnimation)
    {
        if (!animationBegun)
        {
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:ANIMATION_SPEED];
        }
        animationBegun = NO;
     
        //Half the notes-frame
        if (confirmationAnimation)
        {            
            CGRect frame = cellTextview.frame;
            frame.size.width /= 2;
            frame.size.height /= 1.5f;
            cellTextview.frame = frame;
        }
        //Switch back the notes-frame
        else if (returnAnimation)
        {
            CGRect frame = cellTextview.frame;
            frame.size.width *= 2;
            frame.size.height *= 1.5f;
            cellTextview.frame = frame;
        }
        
        //Resign the responder
        [cellTextview resignFirstResponder];
    }
    [super willTransitionToState:state];    
}

@end
