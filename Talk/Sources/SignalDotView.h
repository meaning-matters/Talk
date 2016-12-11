//
//  SignalDotView.h
//  Talk
//
//  Created by Cornelis van der Bent on 29/11/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SignalDotView;


@protocol SignalDotViewDelegate

- (void)signalDotDidStart:(SignalDotView*)dotView;

@end


@interface SignalDotView : UIView

@property (nonatomic, weak) id<SignalDotViewDelegate> delegate;


- (void)startNextWithColor:(UIColor*)color;

- (void)startPreviousWithColor:(UIColor*)color;

- (void)stop;

@end
