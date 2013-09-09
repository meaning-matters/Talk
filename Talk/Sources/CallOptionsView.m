//
//  CallOptionsView.m
//  Talk
//
//  Created by Cornelis van der Bent on 29/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "CallOptionsView.h"
#import "NSTimer+Blocks.h"
#import "Common.h"


// These delays are used to limit the frequency at which mute, speaker and hold can be changed.
// During both timeouts, user taps are discarded (i.e. not fed to delegate).  The first timeout
// is the maximum time the app is given for roundtrip: user-tap to setOn...() reponse.  When the
// roundtrip response is received within the first timeout, a short second timeout blocks user
// input.
#define FIRST_TIMEOUT   2.0
#define SECOND_TIMEOUT  0.5

@interface CallOptionsView ()
{
    NSTimer*    muteTimer;
    NSTimer*    speakerTimer;
    NSTimer*    holdTimer;
}

@end


@implementation CallOptionsView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self setUp];
    }

    return self;
}


- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setUp];
}


- (void)setUp
{
    [[NSBundle mainBundle] loadNibNamed:@"CallOptionsView" owner:self options:nil];
    CGRect frame = self.frame;
    self.view.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    [self addSubview:self.view];

    self.backgroundColor = [UIColor clearColor];

    for (int tag = 1; tag <= 6; tag++)
    {
        UIButton*   button = (UIButton*)[self.view viewWithTag:tag];

        button.backgroundColor = [UIColor clearColor];
        [button setTitle:@"" forState:UIControlStateNormal];
    }
}


- (void)dealloc
{
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    [self setNeedsDisplay];
}


- (void)drawRect:(CGRect)rect
{
    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();

    //// Color Declarations
    UIColor* borderColor = [UIColor colorWithRed: 0.5 green: 0.5 blue: 0.5 alpha: 0.8];
    UIColor* gridLineColor = [UIColor colorWithRed: 0.246 green: 0.246 blue: 0.246 alpha: 0.8];
    UIColor* borderShadowColor = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.5];

    //// Shadow Declarations
    UIColor* borderShadow = borderShadowColor;
    CGSize borderShadowOffset = CGSizeMake(0.1, 2.1);
    CGFloat borderShadowBlurRadius = 4;

    //// Frames
    CGRect frame = self.bounds;

    //// Border Drawing
    UIBezierPath* borderPath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(CGRectGetMinX(frame) + 10, CGRectGetMinY(frame) + 10, 276, 227) cornerRadius: 12];
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, borderShadowOffset, borderShadowBlurRadius, borderShadow.CGColor);
    [borderColor setStroke];
    borderPath.lineWidth = 4;
    [borderPath stroke];
    CGContextRestoreGState(context);

    //// Grid Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(CGRectGetMinX(frame) + 102.5, CGRectGetMinY(frame) + 12)];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 102.5, CGRectGetMinY(frame) + 123)];
    [gridLineColor setStroke];
    bezierPath.lineWidth = 1;
    [bezierPath stroke];

    UIBezierPath* bezier2Path = [UIBezierPath bezierPath];
    [bezier2Path moveToPoint: CGPointMake(CGRectGetMinX(frame) + 12, CGRectGetMinY(frame) + 123.5)];
    [bezier2Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 284, CGRectGetMinY(frame) + 123.5)];
    [gridLineColor setStroke];
    bezier2Path.lineWidth = 1;
    [bezier2Path stroke];

    UIBezierPath* bezier4Path = [UIBezierPath bezierPath];
    [bezier4Path moveToPoint: CGPointMake(CGRectGetMinX(frame) + 102.5, CGRectGetMinY(frame) + 124)];
    [bezier4Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 102.5, CGRectGetMinY(frame) + 235)];
    [gridLineColor setStroke];
    bezier4Path.lineWidth = 1;
    [bezier4Path stroke];

    UIBezierPath* bezier5Path = [UIBezierPath bezierPath];
    [bezier5Path moveToPoint: CGPointMake(CGRectGetMinX(frame) + 193.5, CGRectGetMinY(frame) + 124)];
    [bezier5Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 193.5, CGRectGetMinY(frame) + 235)];
    [gridLineColor setStroke];
    bezier5Path.lineWidth = 1;
    [bezier5Path stroke];

    UIBezierPath* bezier3Path = [UIBezierPath bezierPath];
    [bezier3Path moveToPoint: CGPointMake(CGRectGetMinX(frame) + 193.5, CGRectGetMinY(frame) + 12)];
    [bezier3Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 193.5, CGRectGetMinY(frame) + 123)];
    [gridLineColor setStroke];
    bezier3Path.lineWidth = 1;
    [bezier3Path stroke];

    //// Cleanup
    CGColorSpaceRelease(colorSpace);
}


- (IBAction)muteAction:(id)sender
{
    if (muteTimer == nil)
    {
        muteTimer = [NSTimer scheduledTimerWithTimeInterval:FIRST_TIMEOUT repeats:NO block:^
        {
            muteTimer = nil;
        }];

        [Common dispatchAfterInterval:0.1 onMain:^
        {
            [self.delegate callOptionsViewPressedMuteKey:self];
        }];
    }
}


- (IBAction)keypadAction:(id)sender
{
    [self.delegate callOptionsViewPressedKeypadKey:self];
}


- (IBAction)speakerAction:(id)sender
{
    if (speakerTimer == nil)
    {
        speakerTimer = [NSTimer scheduledTimerWithTimeInterval:FIRST_TIMEOUT repeats:NO block:^
        {
            speakerTimer = nil;
        }];

        // Add short delay to allow redraw of button (also on main thread).  This was only
        // required for speaker button but was, for symmetry, also added for mute and hold.
        [Common dispatchAfterInterval:0.1 onMain:^
        {
            [self.delegate callOptionsViewPressedSpeakerKey:self];
        }];
    }
}


- (IBAction)addAction:(id)sender
{
    [self.delegate callOptionsViewPressedAddKey:self];
}


- (IBAction)holdAction:(id)sender
{
    if (holdTimer == nil)
    {
        holdTimer = [NSTimer scheduledTimerWithTimeInterval:FIRST_TIMEOUT repeats:NO block:^
        {
            holdTimer = nil;
        }];

        [Common dispatchAfterInterval:0.1 onMain:^
        {
            [self.delegate callOptionsViewPressedHoldKey:self];
        }];
    }
}


- (IBAction)groupsAction:(id)sender
{
    [self.delegate callOptionsViewPressedGroupsKey:self];
}


- (void)setOnMute:(BOOL)onMute
{
    if (muteTimer != nil)
    {
        [muteTimer invalidate];
        muteTimer = [NSTimer scheduledTimerWithTimeInterval:SECOND_TIMEOUT repeats:NO block:^
        {
            muteTimer = nil;
        }];
    }

    _onMute = onMute;
    self.muteButton.on = onMute;
}


- (void)setOnSpeaker:(BOOL)onSpeaker
{
    if (speakerTimer != nil)
    {
        [speakerTimer invalidate];
        speakerTimer = [NSTimer scheduledTimerWithTimeInterval:SECOND_TIMEOUT repeats:NO block:^
        {
            speakerTimer = nil;
        }];
    }

    _onSpeaker = onSpeaker;
    self.speakerButton.on = onSpeaker;
}


- (void)setOnHold:(BOOL)onHold
{
    if (holdTimer != nil)
    {
        [holdTimer invalidate];
        holdTimer = [NSTimer scheduledTimerWithTimeInterval:SECOND_TIMEOUT repeats:NO block:^
        {
            holdTimer = nil;
        }];
    }

    _onHold = onHold;
    self.holdButton.on = onHold;
}

@end
