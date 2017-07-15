//
//  GraphicCallStateView.m
//  Talk
//
//  Created by Cornelis van der Bent on 30/11/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import "GraphicCallStateView.h"
#import "SignalDotView.h"
#import "SoundWaveView.h"
#import "Skinning.h"
#import "Common.h"
#import "NSTimer+Blocks.h"


@interface GraphicCallStateView () <SignalDotViewDelegate>

@property (nonatomic, strong) IBOutletCollection(SignalDotView) NSArray* callbackDotViews;
@property (nonatomic, strong) IBOutletCollection(SignalDotView) NSArray* callthruDotViews;

@property (nonatomic, weak) IBOutlet UIImageView* logoImageView;
@property (nonatomic, weak) IBOutlet UIImageView* phoneImageView;
@property (nonatomic, weak) IBOutlet UIImageView* contactImageView;
@property (nonatomic, weak) IBOutlet UIImageView* keypadImageView;
@property (nonatomic, weak) IBOutlet UIImageView* cloudImageView;

@property (nonatomic, strong) NSArray<SoundWaveView*>* callerWaveViews;
@property (nonatomic, strong) NSArray<SoundWaveView*>* calleeWaveViews;

@property (nonatomic, assign) BOOL requestStarted;
@property (nonatomic, assign) BOOL callbackStarted;
@property (nonatomic, assign) BOOL callthruStarted;

@property (nonatomic, strong) NSTimer* soundWaveTimer;

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

    if (self.callbackStarted == YES)
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


- (void)connectCallback
{
    [self stopRequest];
    [self stopCallback];

    for (SignalDotView* dotView in self.callbackDotViews)
    {
        dotView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.7];
    }
}


- (void)stopCallback
{
    for (SignalDotView* dotView in self.callbackDotViews)
    {
        [dotView stop];
    }

    self.callbackStarted = NO;
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


- (void)connectCallthru
{
    for (SignalDotView* dotView in self.callthruDotViews)
    {
        [dotView stop];
    }

    for (SignalDotView* dotView in self.callthruDotViews)
    {
        dotView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.7];
    }

    if ([self.soundWaveTimer isValid])
    {
        return;
    }

    [self.soundWaveTimer invalidate];
    self.soundWaveTimer = [NSTimer scheduledTimerWithInterval:0.5 repeats:YES block:^
    {
        uint32_t value = arc4random_uniform(100);

        if (value > 50)
        {
            if (value % 2 == 0)
            {
                [self.callerWaveViews.firstObject startNextWithColor:[Skinning tintColor]];
            }
            else
            {
                [self.calleeWaveViews.firstObject startNextWithColor:[Skinning tintColor]];
            }
        }
    }];
}


- (void)stopCallthru
{
    [self.soundWaveTimer invalidate];
    self.soundWaveTimer = nil;

    for (SoundWaveView* waveView in self.callerWaveViews)
    {
        [waveView stop];
    }

    for (SoundWaveView* waveView in self.calleeWaveViews)
    {
        [waveView stop];
    }

    self.callthruStarted = NO;
}


- (void)layoutSubviews
{
    [super layoutSubviews];

    // This method is called 2 times; prevent the double creation of the wave views.
    if (self.callerWaveViews == nil || self.calleeWaveViews == nil)
    {
        [self addSoundWaveViews];
    }

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


- (void)addSoundWaveViews
{
    NSMutableArray* waveViews;
    SoundWaveView*  previousView;
    CGFloat         x;
    CGFloat         y;
    CGFloat         width = 7.0;
    CGFloat         height;

    x            = 65.0;
    y            = 80.0;
    height       = 20.0;
    waveViews    = [NSMutableArray array];
    previousView = nil;
    for (int n = 0; n < 24; n++)
    {
        SoundWaveView* view = [[SoundWaveView alloc] initWithFrame:CGRectMake(x, y, width, height)];
        view.direction = SoundWaveRight;
        previousView.next = view;
        [waveViews addObject:view];

        [self addSubview:view];
        previousView = view;

        x      += width;
        y      -= 1;
        height += 2;
    }

    self.callerWaveViews = waveViews;

    x            = x - width;
    y            = 80.0;
    height       = 20.0;
    waveViews    = [NSMutableArray array];
    previousView = nil;
    for (int n = 0; n < 24; n++)
    {
        SoundWaveView* view = [[SoundWaveView alloc] initWithFrame:CGRectMake(x, y, width, height)];
        view.direction = SoundWaveLeft;
        previousView.next = view;
        [waveViews addObject:view];

        [self addSubview:view];
        previousView = view;

        x      -= width;
        y      -= 1;
        height += 2;
    }

    self.calleeWaveViews = waveViews;
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
