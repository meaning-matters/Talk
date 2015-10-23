//
//  NBPersonFieldTableCell.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/7/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//
//  Custom table view cell, holding a label and textfield

#import "NBPersonFieldTableCell.h"

@implementation NBPersonFieldTableCell

@synthesize cellTextfield, cellLabel, cellType, section;

- (void)registerForKeyboardDismiss
{
    //Listen for keyboard-resigning
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resignEditing) name:NF_RESIGN_EDITING object:nil];
}

#pragma mark - Keyboard resigning
- (void)resignEditing
{
    [self endEditing:YES];
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
        //Begin the animation
        if (!animationBegun)
        {
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:ANIMATION_SPEED];
        }
        animationBegun = NO;
        
        //If we're starting to edit, resign the responder
        if (confirmationAnimation)
        {
            isFirstResponder = self.cellTextfield.isFirstResponder;
            [self.cellTextfield performSelector:@selector(resignFirstResponder) withObject:nil afterDelay:0.1f];
        }
        else if (returnAnimation && isFirstResponder)
        {
            //Restore the responder
            [self.cellTextfield becomeFirstResponder];
            isFirstResponder = NO;
        }
        
        //If we go from edit to delete-confirmation
        if (confirmationAnimation)
        {
            isTransitioned = YES;

            //Half the value textfield
            [self mutateTextfieldFrame:cellTextfield half:YES];
        }
        //If we go back from delete-confirmation to edit
        else if (returnAnimation)
        {
            isTransitioned = NO;
            
            //Restore the value textfield
            [self mutateTextfieldFrame:cellTextfield half:NO];
        }        
        [UIView commitAnimations];
    }
    [super willTransitionToState:state];
}

//Support-method to quickly half/restore a textfield frame
- (void)mutateTextfieldFrame:(UITextField*)textField half:(BOOL)halfFrame
{
    CGRect textfieldFrame = textField.frame;
    if (halfFrame)
    {
        textfieldFrame.size.width /= 2;
    }
    else
    {
        textfieldFrame.size.width *= 2;
    }
    textField.frame = textfieldFrame;
}

//DEPRECATED FOR NOW, ENABLE FOR CUSTOM COLOR SCHEME
//#pragma mark - Cell highlighting
/*//Overloaded to color the cell textfield
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    if (highlighted && !self.isHighlighted)
    {
        [self setFontsToSelected:highlighted];
    }
    else if (!highlighted && self.isHighlighted && originalTextfieldColor != nil)
    {
        [self setFontsToSelected:highlighted];
    }
    [super setHighlighted:highlighted animated:animated];
}

//Ensure the text stays selected, not just highlighted
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    [self setFontsToSelected:selected];
}

//Support-method to quickly set the font color
- (void)setFontsToSelected:(BOOL)selected
{
    if (selected)
    {
        if (originalTextfieldColor == nil)
        {
            originalTextfieldColor = cellTextfield.textColor;
        }
        [self.cellTextfield setTextColor:[UIColor whiteColor]];
    }
    else if (originalTextfieldColor != nil)
    {
        //Execute this with delay so we can return YES
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void)
        {
            [self.cellTextfield setTextColor:originalTextfieldColor];
        });

    }
}*/

#pragma mark - Cleanup
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
