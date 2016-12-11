//
//  GraphicCallStateView.m
//  Talk
//
//  Created by Cornelis van der Bent on 30/11/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import "GraphicCallStateView.h"
#import "SignalDotView.h"
#import "Skinning.h"
#import "Common.h"


@interface GraphicCallStateView () <SignalDotViewDelegate>

@property (nonatomic, strong) IBOutletCollection(SignalDotView) NSArray* callbackDotViews;
@property (nonatomic, strong) IBOutletCollection(SignalDotView) NSArray* callthruDotViews;

@property (nonatomic, weak) IBOutlet UIImageView* logoImageView;
@property (nonatomic, weak) IBOutlet UIImageView* phoneImageView;
@property (nonatomic, weak) IBOutlet UIImageView* contactImageView;
@property (nonatomic, weak) IBOutlet UIImageView* keypadImageView;
@property (nonatomic, weak) IBOutlet UIImageView* cloudImageView;

@property (nonatomic, assign) BOOL requestStarted;
@property (nonatomic, assign) BOOL callbackStarted;
@property (nonatomic, assign) BOOL callthruStarted;

@end


@implementation GraphicCallStateView

- (void)setCallingContact:(BOOL)callingContact
{
    _callingContact = callingContact;

    self.keypadImageView.hidden  = self.callingContact;
    self.contactImageView.hidden = !self.callingContact;
}


- (void)startRequest
{
    if (self.requestStarted == YES)
    {
        return;
    }

    if (self.callbackStarted)
    {
        [self stopCallback];
    }

    [self.callbackDotViews.firstObject startPreviousWithColor:[Skinning tintColor]];

    self.requestStarted = YES;
}


- (void)stopRequest
{
    for (SignalDotView* dotView in self.callbackDotViews)
    {
        [dotView stop];
    }

    self.requestStarted = NO;
    
    self.logoImageView.hidden = YES;
    self.phoneImageView.hidden = NO;
}


- (void)startCallback
{
    if (self.callbackStarted == YES)
    {
        return;
    }

    if (self.requestStarted == YES)
    {
        [self stopRequest];
    }

    [self.callbackDotViews.lastObject startNextWithColor:[UIColor colorWithWhite:1.0 alpha:0.7]];

    self.callbackStarted = YES;
}


- (void)stopCallback
{
    for (SignalDotView* dotView in self.callbackDotViews)
    {
        [dotView stop];
    }

    self.callbackStarted = NO;
}


- (void)connectCallback
{
    [self stopRequest];
    [self stopCallback];

    for (SignalDotView* dotView in self.callbackDotViews)
    {
        dotView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.7];
    }
}


- (void)startCallthru
{
    if (self.callthruStarted == YES)
    {
        return;
    }

    [self.callthruDotViews.lastObject startNextWithColor:[UIColor colorWithWhite:1.0 alpha:0.7]];

    self.callthruStarted = YES;
}


- (void)stopCallthru
{
    for (SignalDotView* dotView in self.callthruDotViews)
    {
        [dotView stop];
    }

    self.callthruStarted = NO;
}


- (void)connectCallthru
{
    [self stopCallthru];

    for (SignalDotView* dotView in self.callthruDotViews)
    {
        dotView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.7];
    }
}


- (void)layoutSubviews
{
    [super layoutSubviews];

    [self setTintColor:[UIColor whiteColor] ofImageView:self.phoneImageView];
    [self setTintColor:[UIColor whiteColor] ofImageView:self.contactImageView];
    [self setTintColor:[UIColor whiteColor] ofImageView:self.keypadImageView];
    [self setTintColor:[UIColor whiteColor] ofImageView:self.cloudImageView];

    self.keypadImageView.hidden  = self.callingContact;
    self.contactImageView.hidden = !self.callingContact;

    [self.callbackDotViews.firstObject setDelegate:self];
    [self.callthruDotViews.firstObject setDelegate:self];
}


- (void)setTintColor:(UIColor*)tintColor ofImageView:(UIImageView*)imageView
{
    imageView.image = [imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

    [imageView setTintColor:tintColor];
}


- (void)wobbleImageView:(UIImageView*)imageView
{
    CAKeyframeAnimation * animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    animation.values = @[[NSValue valueWithCATransform3D:CATransform3DMakeRotation(+0.2, 0, 0, 1)],
                         [NSValue valueWithCATransform3D:CATransform3DMakeRotation(-0.2f, 0, 0, 1)]];
    animation.autoreverses = YES;
    animation.repeatCount  = 4;
    animation.duration     = 0.05f;

    [imageView.layer addAnimation:animation forKey:nil] ;
}


#pragma mark - SignalDotViewDelegate

- (void)signalDotDidStart:(SignalDotView*)dotView
{
    if (dotView == self.callbackDotViews.firstObject)
    {
        [self wobbleImageView:self.phoneImageView];
    }

    if (dotView == self.callthruDotViews.firstObject)
    {
        [self wobbleImageView:self.callingContact ? self.contactImageView : self.keypadImageView];
    }
}

@end
