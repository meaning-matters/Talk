//
//  UIView+AnimateHidden.h
//  Talk
//
//  Created by Cornelis van der Bent on 30/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (AnimateHidden)

- (void)setHiddenAnimated:(BOOL)hide withDuration:(NSTimeInterval)duration completion:(void (^)())completion;

- (void)setHiddenAnimated:(BOOL)hide withDuration:(NSTimeInterval)duration;

- (void)setHiddenAnimated:(BOOL)hide;

@end
