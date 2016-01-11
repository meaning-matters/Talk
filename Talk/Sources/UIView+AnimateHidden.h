//
//  UIView+AnimateHidden.h
//  Talk
//
//  Created by Cornelis van der Bent on 30/03/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface UIView (AnimateHidden)

- (void)setHiddenAnimated:(BOOL)hide withDuration:(NSTimeInterval)duration completion:(void (^)())completion;

- (void)setHiddenAnimated:(BOOL)hide withDuration:(NSTimeInterval)duration;

- (void)setHiddenAnimated:(BOOL)hide;

@end
