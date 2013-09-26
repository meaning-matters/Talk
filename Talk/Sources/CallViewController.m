//
//  CallViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 26/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>   //### For SoloAmbient
#import "CallViewController.h"
#import "Common.h"
#import "CallManager.h"
#import "CallMessageView.h"
#import "NSTimer+Blocks.h"
#import "DtmfPlayer.h"
#import "UIView+AnimateHidden.h"
#import "NSObject+Blocks.h"


const NSTimeInterval    TransitionDuration = 0.5;


@interface CallViewController ()
{
    CallOptionsView*    callOptionsView;
    CallKeypadView*     callKeypadView;
    CallMessageView*    callMessageView;
    NSTimer*            durationTimer;
    int                 duration;
}

@end


@implementation CallViewController

- (id)init
{
    if (self = [super initWithNibName:@"CallView" bundle:nil])
    {
        _calls = [NSMutableArray array];

        callOptionsView.delegate = self;
        callKeypadView.delegate = self;

        [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    }

    return self;
}


- (id)initWithCall:(Call*)call
{
    if (self = [self init])
    {
        [self addCall:call];
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    // Clear backgrounds that are only handy for UI design.
    self.topView.backgroundColor        = [UIColor clearColor];
    self.centerRootView.backgroundColor = [UIColor clearColor];
    self.bottomView.backgroundColor     = [UIColor clearColor];

    Call*   call = [self.calls lastObject];
    self.infoLabel.text   = [call.phoneNumber infoString];
    self.calleeLabel.text = [call.phoneNumber asYouTypeFormat];
    self.statusLabel.text = [call stateString];
    self.dtmfLabel.text   = @"";

    [self.calleeLabel setFont:[Common phoneFontOfSize:38]];
    [self.dtmfLabel   setFont:[Common phoneFontOfSize:38]];

    CGRect  frame = CGRectMake(0, 0, self.centerRootView.frame.size.width, self.centerRootView.frame.size.height);
    callOptionsView = [[CallOptionsView alloc] initWithFrame:frame];
    callKeypadView  = [[CallKeypadView  alloc] initWithFrame:frame];
    callMessageView = [[CallMessageView alloc] initWithFrame:frame];

    callOptionsView.delegate = self;
    callKeypadView.delegate  = self;

    [self drawTopImage];
    [self.centerRootView addSubview:callOptionsView];
    [self drawBottomImage];

    [self drawEndButton];
    [self drawHideButton];
    [self drawRetryButton];
    self.hideButton.hidden  = YES;
    self.retryButton.hidden = YES;

    callOptionsView.muteButton.enabled   = NO;
    callOptionsView.keypadButton.enabled = NO;
    callOptionsView.addButton.enabled    = NO;
    callOptionsView.holdButton.enabled   = NO;
}


- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    switch ((int)self.view.frame.size.height)
    {
        case 460:   // 320x480 screen.
            [Common setY:106 ofView:self.centerRootView];
            [Common setY:367 ofView:self.bottomView];
            break;

        case 420:   // 320x480 screen with in-call iOS flasher at top.
            [Common setY:96  ofView:self.centerRootView];
            [Common setY:357 ofView:self.bottomView];
            break;

        case 548:   // 320x568 screen.
            [Common setY:150 ofView:self.centerRootView];
            [Common setY:455 ofView:self.bottomView];
            break;

        case 528:   // 320x568 screen with in-call iOS flasher at top.
            [Common setY:140 ofView:self.centerRootView];
            [Common setY:435 ofView:self.bottomView];
            break;
    }
}


#pragma mark - Drawing

- (void)drawTopImage
{
    //// Start Image
    UIGraphicsBeginImageContextWithOptions(self.topImageView.frame.size, NO, 0.0);

    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();

    //// Color Declarations
    UIColor* gradientBottomColor = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.8];
    UIColor* gradientTopColor = [UIColor colorWithRed: 0.101 green: 0.101 blue: 0.101 alpha: 0.8];
    UIColor* lineColor = [UIColor colorWithRed: 0.249 green: 0.249 blue: 0.249 alpha: 0.8];

    //// Gradient Declarations
    NSArray* gradientColors = [NSArray arrayWithObjects:
                               (id)gradientTopColor.CGColor,
                               (id)gradientBottomColor.CGColor, nil];
    CGFloat gradientLocations[] = {0, 1};
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)gradientColors, gradientLocations);

    //// Rectangle Drawing
    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: CGRectMake(0, 0, 320, 93)];
    CGContextSaveGState(context);
    [rectanglePath addClip];
    CGContextDrawLinearGradient(context, gradient, CGPointMake(160, -0), CGPointMake(160, 93), 0);
    CGContextRestoreGState(context);

    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(0, 92.5)];
    [bezierPath addLineToPoint: CGPointMake(320, 92.5)];
    [lineColor setStroke];
    bezierPath.lineWidth = 1;
    [bezierPath stroke];

    //// End Image
    UIImage* result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    //// Cleanup
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);

    self.topImageView.image = result;
    [self.topImageView setNeedsDisplay];
}


- (void)drawBottomImage
{
    //// Start Image
    UIGraphicsBeginImageContextWithOptions(self.bottomImageView.frame.size, NO, 0.0);

    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();

    //// Color Declarations
    UIColor* gradientBottomColor = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.8];
    UIColor* gradientTopColor = [UIColor colorWithRed: 0.101 green: 0.101 blue: 0.101 alpha: 0.8];
    UIColor* lineColor = [UIColor colorWithRed: 0.35 green: 0.35 blue: 0.35 alpha: 0.8];

    //// Gradient Declarations
    NSArray* gradientColors = [NSArray arrayWithObjects:
                               (id)gradientTopColor.CGColor,
                               (id)gradientBottomColor.CGColor, nil];
    CGFloat gradientLocations[] = {0, 1};
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)gradientColors, gradientLocations);

    //// Rectangle Drawing
    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: CGRectMake(0, 0, 320, 93)];
    CGContextSaveGState(context);
    [rectanglePath addClip];
    CGContextDrawLinearGradient(context, gradient, CGPointMake(160, -0), CGPointMake(160, 93), 0);
    CGContextRestoreGState(context);

    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(0, 0.5)];
    [bezierPath addLineToPoint: CGPointMake(320, 0.5)];
    [lineColor setStroke];
    bezierPath.lineWidth = 1;
    [bezierPath stroke];

    //// End Image
    UIImage* result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    //// Cleanup
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);

    self.bottomImageView.image = result;
    [self.bottomImageView setNeedsDisplay];
}


- (void)drawEndButton
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    UIColor* normalGradientBottom = [UIColor colorWithRed: 0.802 green: 0.109 blue: 0 alpha: 0.8];
    UIColor* normalGradientTop = [UIColor colorWithRed: 0.799 green: 0.397 blue: 0.397 alpha: 0.8];
    UIColor* highlightGradientTop = [UIColor colorWithRed: 0.502 green: 0.253 blue: 0.257 alpha: 0.8];
    UIColor* highlightGradientBottom = [UIColor colorWithRed: 0.5 green: 0.051 blue: 0 alpha: 0.8];
    UIColor* disableGradientTop = [UIColor colorWithRed: 0.4 green: 0.4 blue: 0.4 alpha: 0.8];
    UIColor* disableGradientBottom = [UIColor colorWithRed: 0.1 green: 0.1 blue: 0.1 alpha: 0.8];

    //// Gradient Declarations
    NSArray* normalGradientColors = [NSArray arrayWithObjects:
                                     (id)normalGradientTop.CGColor,
                                     (id)normalGradientBottom.CGColor, nil];
    CGFloat normalGradientLocations[] = {0, 1};
    CGGradientRef normalGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)normalGradientColors, normalGradientLocations);
    NSArray* highlightGradientColors = [NSArray arrayWithObjects:
                                   (id)highlightGradientTop.CGColor,
                                   (id)highlightGradientBottom.CGColor, nil];
    CGFloat highlightGradientLocations[] = {0, 1};
    CGGradientRef highlightGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)highlightGradientColors, highlightGradientLocations);
    NSArray* disableGradientColors = [NSArray arrayWithObjects:
                                   (id)disableGradientTop.CGColor,
                                   (id)disableGradientBottom.CGColor, nil];
    CGFloat disableGradientLocations[] = {0, 1};
    CGGradientRef disableGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)disableGradientColors, disableGradientLocations);

    UIImage* normalImage = [self drawButtonImageWithGradient:normalGradient size:self.endButton.frame.size];
    UIImage* highlightImage = [self drawButtonImageWithGradient:highlightGradient size:self.endButton.frame.size];
    UIImage* disableImage = [self drawButtonImageWithGradient:disableGradient size:self.endButton.frame.size];

    [self.endButton setBackgroundImage:normalImage forState:UIControlStateNormal];
    [self.endButton setBackgroundImage:highlightImage forState:UIControlStateHighlighted];
    [self.endButton setBackgroundImage:disableImage forState:UIControlStateDisabled];
    [self.endButton setNeedsDisplay];

    //// Cleanup
    CGGradientRelease(normalGradient);
    CGGradientRelease(highlightGradient);
    CGGradientRelease(disableGradient);
    CGColorSpaceRelease(colorSpace);
}


- (void)drawHideButton
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    UIColor* normalGradientTop = [UIColor colorWithRed: 0.4 green: 0.4 blue: 0.4 alpha: 0.8];
    UIColor* normalGradientBottom = [UIColor colorWithRed: 0.1 green: 0.1 blue: 0.1 alpha: 0.8];
    UIColor* highlightGradientBottom = [UIColor colorWithRed: 0 green: 0.373 blue: 1 alpha: 0.8];
    UIColor* highlightGradientTop = [UIColor colorWithRed: 0.203 green: 0.497 blue: 1 alpha: 0.8];

    //// Gradient Declarations
    NSArray* normalGradientColors = [NSArray arrayWithObjects:
                                     (id)normalGradientTop.CGColor,
                                     (id)normalGradientBottom.CGColor, nil];
    CGFloat normalGradientLocations[] = {0, 1};
    CGGradientRef normalGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)normalGradientColors, normalGradientLocations);
    NSArray* highlightGradientColors = [NSArray arrayWithObjects:
                                   (id)highlightGradientTop.CGColor,
                                   (id)highlightGradientBottom.CGColor, nil];
    CGFloat highlightGradientLocations[] = {0, 1};
    CGGradientRef highlightGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)highlightGradientColors, highlightGradientLocations);

    UIImage* normalImage = [self drawButtonImageWithGradient:normalGradient size:self.hideButton.frame.size];
    UIImage* highlightImage = [self drawButtonImageWithGradient:highlightGradient size:self.hideButton.frame.size];

    [self.hideButton setBackgroundImage:normalImage forState:UIControlStateNormal];
    [self.hideButton setBackgroundImage:highlightImage forState:UIControlStateHighlighted];
    [self.hideButton setNeedsDisplay];

    //// Cleanup
    CGGradientRelease(normalGradient);
    CGGradientRelease(highlightGradient);
    CGColorSpaceRelease(colorSpace);
}


- (void)drawRetryButton
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    UIColor* normalGradientTop = [UIColor colorWithRed: 0.4 green: 0.4 blue: 0.4 alpha: 0.8];
    UIColor* normalGradientBottom = [UIColor colorWithRed: 0.1 green: 0.1 blue: 0.1 alpha: 0.8];
    UIColor* highlightGradientBottom = [UIColor colorWithRed: 0 green: 0.373 blue: 1 alpha: 0.8];
    UIColor* highlightGradientTop = [UIColor colorWithRed: 0.203 green: 0.497 blue: 1 alpha: 0.8];

    //// Gradient Declarations
    NSArray* normalGradientColors = [NSArray arrayWithObjects:
                                     (id)normalGradientTop.CGColor,
                                     (id)normalGradientBottom.CGColor, nil];
    CGFloat normalGradientLocations[] = {0, 1};
    CGGradientRef normalGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)normalGradientColors, normalGradientLocations);
    NSArray* highlightGradientColors = [NSArray arrayWithObjects:
                                        (id)highlightGradientTop.CGColor,
                                        (id)highlightGradientBottom.CGColor, nil];
    CGFloat highlightGradientLocations[] = {0, 1};
    CGGradientRef highlightGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)highlightGradientColors, highlightGradientLocations);

    UIImage* normalImage = [self drawButtonImageWithGradient:normalGradient size:self.retryButton.frame.size];
    UIImage* highlightImage = [self drawButtonImageWithGradient:highlightGradient size:self.retryButton.frame.size];

    [self.retryButton setBackgroundImage:normalImage forState:UIControlStateNormal];
    [self.retryButton setBackgroundImage:highlightImage forState:UIControlStateHighlighted];
    [self.retryButton setNeedsDisplay];

    //// Cleanup
    CGGradientRelease(normalGradient);
    CGGradientRelease(highlightGradient);
    CGColorSpaceRelease(colorSpace);
}


- (UIImage*)drawButtonImageWithGradient:(CGGradientRef)gradient size:(CGSize)size
{
    //// Start Image
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);

    //// General Declarations
    CGContextRef context = UIGraphicsGetCurrentContext();

    //// Color Declarations
    UIColor* strokeColor = [UIColor colorWithRed: 0.297 green: 0.297 blue: 0.297 alpha: 0.8];
    UIColor* shadowColor2 = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.8];

    //// Shadow Declarations
    UIColor* innerShadow = shadowColor2;
    CGSize innerShadowOffset = CGSizeMake(0.1, 2.1);
    CGFloat innerShadowBlurRadius = 4;

    //// Abstracted Attributes
    CGRect roundedRectangleRect = CGRectMake(2, 2, size.width - 4.0f, 48);

    //// Rounded Rectangle Drawing
    UIBezierPath* roundedRectanglePath = [UIBezierPath bezierPathWithRoundedRect: roundedRectangleRect cornerRadius: 12];
    CGContextSaveGState(context);
    [roundedRectanglePath addClip];
    CGContextDrawLinearGradient(context, gradient, CGPointMake(65, 2), CGPointMake(65, 50), 0);
    CGContextRestoreGState(context);

    ////// Rounded Rectangle Inner Shadow
    CGRect roundedRectangleBorderRect = CGRectInset([roundedRectanglePath bounds], -innerShadowBlurRadius, -innerShadowBlurRadius);
    roundedRectangleBorderRect = CGRectOffset(roundedRectangleBorderRect, -innerShadowOffset.width, -innerShadowOffset.height);
    roundedRectangleBorderRect = CGRectInset(CGRectUnion(roundedRectangleBorderRect, [roundedRectanglePath bounds]), -1, -1);

    UIBezierPath* roundedRectangleNegativePath = [UIBezierPath bezierPathWithRect: roundedRectangleBorderRect];
    [roundedRectangleNegativePath appendPath: roundedRectanglePath];
    roundedRectangleNegativePath.usesEvenOddFillRule = YES;

    CGContextSaveGState(context);
    {
        CGFloat xOffset = innerShadowOffset.width + round(roundedRectangleBorderRect.size.width);
        CGFloat yOffset = innerShadowOffset.height;
        CGContextSetShadowWithColor(context,
                                    CGSizeMake(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset)),
                                    innerShadowBlurRadius,
                                    innerShadow.CGColor);

        [roundedRectanglePath addClip];
        CGAffineTransform transform = CGAffineTransformMakeTranslation(-round(roundedRectangleBorderRect.size.width), 0);
        [roundedRectangleNegativePath applyTransform: transform];
        [[UIColor grayColor] setFill];
        [roundedRectangleNegativePath fill];
    }
    CGContextRestoreGState(context);

    [strokeColor setStroke];
    roundedRectanglePath.lineWidth = 4;
    [roundedRectanglePath stroke];

    //// End Image
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}


#pragma mark - Options Delegate

- (void)callOptionsViewPressedMuteKey:(CallOptionsView*)optionsView
{
    [[CallManager sharedManager] setCall:[self.calls lastObject] onMute:!optionsView.onMute];   //### Should be active call.
}


- (void)callOptionsViewPressedKeypadKey:(CallOptionsView*)optionsView
{
    [UIView transitionFromView:callOptionsView
                        toView:callKeypadView
                      duration:TransitionDuration
                       options:UIViewAnimationOptionTransitionFlipFromRight
                    completion:nil];
    
    [self showSmallEndButton];
    
    [self animateView:self.hideButton  fromHidden:YES toHidden:NO];
    [self animateView:self.retryButton fromHidden:YES toHidden:YES];
    [self animateView:self.infoLabel   fromHidden:YES toHidden:YES];
    [self animateView:self.calleeLabel fromHidden:YES toHidden:YES];
    [self animateView:self.statusLabel fromHidden:YES toHidden:YES];
    [self animateView:self.dtmfLabel   fromHidden:YES toHidden:NO];
}


- (void)callOptionsViewPressedSpeakerKey:(CallOptionsView*)optionsView
{
    [[CallManager sharedManager] setOnSpeaker:!optionsView.onSpeaker];
}


- (void)callOptionsViewPressedAddKey:(CallOptionsView*)optionsView
{
    
}


- (void)callOptionsViewPressedHoldKey:(CallOptionsView*)optionsView
{    
    [[CallManager sharedManager] setCall:[self.calls lastObject] onHold:!optionsView.onHold];  //### Should be active call.
}


- (void)callOptionsViewPressedGroupsKey:(CallOptionsView*)optionsView
{

}


#pragma mark - Keypad Delegate

- (void)callKeypadView:(CallKeypadView*)keypadView pressedDigitKey:(KeypadKey)key
{
    self.dtmfLabel.text = [NSString stringWithFormat:@"%@%c", self.dtmfLabel.text, key];

    [[DtmfPlayer sharedPlayer] playCharacter:key atVolume:1.5f];

    [[CallManager sharedManager] sendCall:[self.calls lastObject] dtmfCharacter:key];
}


#pragma mark - Call Delegate

- (void)call:(Call*)call didUpdateState:(CallState)state
{
    self.statusLabel.text = [call stateString];
}


#pragma Message View

- (void)showMessageViewWithText:(NSString*)text
{
    [UIView transitionFromView:[self.centerRootView.subviews lastObject]
                        toView:callMessageView
                      duration:TransitionDuration
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    completion:nil];

    callMessageView.label.text = text;

    [self showSmallEndButton];

    [self animateView:self.hideButton  fromHidden:YES toHidden:YES];
    [self animateView:self.retryButton fromHidden:YES toHidden:NO];
    [self animateView:self.infoLabel   fromHidden:YES toHidden:NO];
    [self animateView:self.calleeLabel fromHidden:YES toHidden:NO];
    [self animateView:self.statusLabel fromHidden:YES toHidden:NO];
    [self animateView:self.dtmfLabel   fromHidden:YES toHidden:YES];
}


#pragma mark - Button Actions

- (IBAction)endAction:(id)sender
{
    Call* call = [self.calls lastObject];   //### Should be active call.

    call.readyForCleanup = YES;
    [[CallManager sharedManager] endCall:call];
}


- (IBAction)hideAction:(id)sender
{
    [UIView transitionFromView:callKeypadView
                        toView:callOptionsView
                      duration:TransitionDuration
                       options:UIViewAnimationOptionTransitionFlipFromLeft
                    completion:nil];

    [self showLargeEndButton];

    [self animateView:self.hideButton  fromHidden:YES toHidden:YES];
    [self animateView:self.retryButton fromHidden:YES toHidden:YES];
    [self animateView:self.infoLabel   fromHidden:YES toHidden:NO];
    [self animateView:self.calleeLabel fromHidden:YES toHidden:NO];
    [self animateView:self.statusLabel fromHidden:YES toHidden:NO];
    [self animateView:self.dtmfLabel   fromHidden:YES toHidden:YES];
}


- (IBAction)retryAction:(id)sender
{
    if ([[CallManager sharedManager] retryCall:[self.calls lastObject]] == YES)
    {
        [UIView transitionFromView:callMessageView
                            toView:callOptionsView
                          duration:TransitionDuration
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        completion:nil];

        [self showLargeEndButton];

        [self animateView:self.hideButton  fromHidden:YES toHidden:YES];
        [self animateView:self.retryButton fromHidden:NO  toHidden:YES];
        [self animateView:self.infoLabel   fromHidden:NO  toHidden:NO];
        [self animateView:self.calleeLabel fromHidden:NO  toHidden:NO];
        [self animateView:self.statusLabel fromHidden:NO  toHidden:NO];
        [self animateView:self.dtmfLabel   fromHidden:YES toHidden:YES];
    }
}


#pragma mark - Utility

- (void)animateView:(UIView*)view fromHidden:(BOOL)fromHide toHidden:(BOOL)toHide
{
    __weak UIView*  weakView = view;

    [weakView setHiddenAnimated:fromHide withDuration:(TransitionDuration / 2) completion:^
    {
        [weakView setHiddenAnimated:toHide withDuration:(TransitionDuration / 2) completion:nil];
    }];
}


- (void)showLargeEndButton
{
    [self showEndButtonWithWidth:280 imageName:@"HangupPhone"];
}


- (void)showSmallEndButton
{
    [self showEndButtonWithWidth:130 imageName:@"HangupPhoneSmall"];
}


- (void)showEndButtonWithWidth:(CGFloat)width imageName:(NSString*)imageName
{
    [self.endButton setHiddenAnimated:YES withDuration:(TransitionDuration / 2) completion:^
     {
         [Common setWidth:width ofView:self.endButton];
         [self drawEndButton];
         [self.endButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
         [self.endButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateHighlighted];

         [self.endButton setHiddenAnimated:NO withDuration:(TransitionDuration / 2) completion:nil];
     }];
}


#pragma mark - Public API

- (void)addCall:(Call*)call
{
    [self.calls addObject:call];
}


- (void)endCall:(Call*)call
{
    [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
    [UIApplication sharedApplication].idleTimerDisabled = NO;

#warning Move this to SipInterface, and do when last call in array has been ended.
    [Common dispatchAfterInterval:0.5 onMain:^
    {
        // Delay this (which route backs to speaker) to prevent 'noisy click' during brief moment
        // that PISIP has not shutdown audio yet.  Also prevents Speaker option button to light up
        // on CallView just before it disappears.
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategorySoloAmbient error:nil];
    }];

    //KEES [self.calls removeObject:call];
}


- (void)updateCallCalling:(Call*)call
{
    self.statusLabel.text = [call stateString];
}


- (void)updateCallRinging:(Call*)call
{
    self.statusLabel.text = [call stateString];
}


- (void)updateCallConnecting:(Call*)call
{
    self.statusLabel.text = [call stateString];
}


- (void)updateCallConnected:(Call*)call
{
    self.statusLabel.text = [call stateString];

    call.readyForCleanup = YES;

    callOptionsView.muteButton.enabled   = YES;
    callOptionsView.keypadButton.enabled = YES;
    callOptionsView.addButton.enabled    = NO;
    callOptionsView.holdButton.enabled   = YES;

    duration = 1;
    durationTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^
    {
        if (duration < 3600)
        {
            self.statusLabel.text = [NSString stringWithFormat:@"%02d:%02d",
                                     (duration % 3600) / 60,
                                     duration % 60];
        }
        else
        {
            self.statusLabel.text = [NSString stringWithFormat:@"%d:%02d:%02d",
                                     duration / 3600,
                                     (duration % 3600) / 60,
                                     duration % 60];
        }

        duration++;
    }];
}


- (void)updateCallEnding:(Call*)call
{
    [durationTimer invalidate];
    durationTimer = nil;

    self.statusLabel.text = [call stateString];
}


- (void)updateCallEnded:(Call*)call
{
    [durationTimer invalidate];
    durationTimer = nil;

    [self endCall:call];
}


- (void)updateCallBusy:(Call*)call
{
    self.statusLabel.text = [call stateString];
}


- (void)updateCallDeclined:(Call*)call
{
    self.statusLabel.text = [call stateString];
}


- (void)updateCallFailed:(Call*)call message:(NSString*)message;
{
    if (call == nil)
    {
        NSLog(@"//### Call is nil (failed)");
        Call* call = [[Call alloc] init];
        call.state = CallStateFailed;
    }

    [durationTimer invalidate];
    durationTimer = nil;

    self.statusLabel.text = [call stateString];
    [self showMessageViewWithText:message];
}


- (void)setCall:(Call*)call onMute:(BOOL)onMute
{
#warning Only update when current call.
    callOptionsView.onMute = onMute;
}


- (void)setCall:(Call*)call onHold:(BOOL)onHold
{
#warning Only update when current call.
#warning Set Call onHold variable -  also for others.
    callOptionsView.onHold = onHold;
}


- (void)setOnSpeaker:(BOOL)onSpeaker
{
    callOptionsView.onSpeaker = onSpeaker;
    [[UIDevice currentDevice] setProximityMonitoringEnabled:!onSpeaker];
}


- (void)setSpeakerEnable:(BOOL)enable
{
    callOptionsView.speakerButton.enabled = enable;
}

@end
