//
//  UIView+AnimateHidden.m
//  Talk
//
//  Created by Cornelis van der Bent on 30/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "UIView+AnimateHidden.h"

@implementation UIView (AnimateHidden)

- (void)setHiddenAnimated:(BOOL)hide withDuration:(NSTimeInterval)duration completion:(void (^)())completion
{
    // For interoperability with hidden property: set start alpha.
    self.alpha = !self.hidden;

    // To see the animation.
    self.hidden = NO;

    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationCurveLinear
                     animations:^
    {
        self.alpha = hide ? 0.0001 : 0.9099;    // A value just off, prevents animation from being skipped.
    }
                     completion:^(BOOL finished)
    {
        self.hidden = hide;

        // For interoperability with hidden property: alpha must end at 1.
        self.alpha = 1;

        if (completion != nil)
        {
            completion();
        }
    }];
}


- (void)setHiddenAnimated:(BOOL)hide withDuration:(NSTimeInterval)duration
{
    [self setHiddenAnimated:hide withDuration:duration completion:nil];
}


- (void)setHiddenAnimated:(BOOL)hide
{
    [self setHiddenAnimated:hide withDuration:0.5 completion:nil];
}

@end
