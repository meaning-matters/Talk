//
//  NBPeopleTableViewCell.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/30/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import "NBPeopleTableViewCell.h"

@implementation NBPeopleTableViewCell

//DEPRECATED, re-enable for situations like a custom color scheme
/*#pragma mark - Cell highlighting
//Overloaded to color the cell textfield
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    if (highlighted && !self.isHighlighted)
    {
        [self setFontsToSelected:highlighted];
    }
    else if (!highlighted && self.isHighlighted && originalLabelColor != nil)
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
        if (originalLabelColor == nil)
        {
            originalLabelColor = self.textLabel.textColor;
        }
        [self.textLabel setTextColor:[UIColor whiteColor]];        
    }
    else if (originalLabelColor != nil)
    {
        if (!self.selected && !self.highlighted)
        {
            //Execute this with delay so we can return YES
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.25f * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void)
            {
               [self.textLabel setTextColor:originalLabelColor];
            });
        }
        else if (self.highlighted)
        {
           [self.textLabel setTextColor:originalLabelColor];
        }
    }
}*/

@end
