//
//  UIView+AnimateHidden.m
//  Talk
//
//  Created by Cornelis van der Bent on 30/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "UIView+AnimateHidden.h"

@implementation UIView (AnimateHidden)

- (void)setHiddenAnimated:(BOOL)hide
{
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:UIViewAnimationCurveEaseOut
                     animations:^
    {
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        if (hide)
        {
            self.alpha = 0;
        }
        else
        {
            self.hidden = NO;
            self.alpha = 1;
        }
    }
                     completion:^(BOOL finished)
    {
        if (hide)
        {
            self.hidden= YES;
            self.alpha = 1;
        }
    }];
}

@end
