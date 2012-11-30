//
//  CallKeypadView.m
//  Talk
//
//  Created by Cornelis van der Bent on 29/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "CallKeypadView.h"
#import "Common.h"

@implementation CallKeypadView

@synthesize view          = _view;
@synthesize key1Button    = _key1Button;
@synthesize key2Button    = _key2Button;
@synthesize key3Button    = _key3Button;
@synthesize key4Button    = _key4Button;
@synthesize key5Button    = _key5Button;
@synthesize key6Button    = _key6Button;
@synthesize key7Button    = _key7Button;
@synthesize key8Button    = _key8Button;
@synthesize key9Button    = _key9Button;
@synthesize keyStarButton = _keyStarButton;
@synthesize key0Button    = _key0Button;
@synthesize keyHashButton = _keyHashButton;
@synthesize delegate      = _delegate;


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
    [[NSBundle mainBundle] loadNibNamed:@"CallKeypadView" owner:self options:nil];
    CGRect frame = self.frame;
    self.view.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    [self addSubview:self.view];

    self.backgroundColor = [UIColor clearColor];

    for (int tag = 1; tag <= 12; tag++)
    {
        UIButton*   button = (UIButton*)[self.view viewWithTag:tag];

        button.backgroundColor = [UIColor clearColor];
        [button setTitle:@"" forState:UIControlStateNormal];
    }
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
    UIColor* keyNormalGradientTop = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.8];
    UIColor* keyNormalGradientBottom = [UIColor colorWithRed: 0.103 green: 0.103 blue: 0.102 alpha: 0.8];
    UIColor* keyHighlightGradientColor = [UIColor colorWithRed: 0 green: 0.373 blue: 1 alpha: 0.8];
    UIColor* keyHighlightGradientColor2 = [UIColor colorWithRed: 0.203 green: 0.497 blue: 1 alpha: 0.8];
    UIColor* borderShadowColor = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.5];

    //// Gradient Declarations
    NSArray* keyNormalGradientColors = [NSArray arrayWithObjects:
                                        (id)keyNormalGradientTop.CGColor,
                                        (id)keyNormalGradientBottom.CGColor, nil];
    CGFloat keyNormalGradientLocations[] = {0, 0.98};
    CGGradientRef keyNormalGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)keyNormalGradientColors, keyNormalGradientLocations);
    NSArray* keyHighlightGradientColors = [NSArray arrayWithObjects:
                                           (id)keyHighlightGradientColor.CGColor,
                                           (id)keyHighlightGradientColor2.CGColor, nil];
    CGFloat keyHighlightGradientLocations[] = {0, 1};
    CGGradientRef keyHighlightGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)keyHighlightGradientColors, keyHighlightGradientLocations);

    //// Shadow Declarations
    UIColor* borderShadow = borderShadowColor;
    CGSize borderShadowOffset = CGSizeMake(0.1, 2.1);
    CGFloat borderShadowBlurRadius = 4;
    
    //// Frames
    CGRect frame = self.bounds;

    //// Border Drawing
    UIBezierPath* borderPath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(CGRectGetMinX(frame) + 10, CGRectGetMinY(frame) + 6, 276, 227) cornerRadius: 12];
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, borderShadowOffset, borderShadowBlurRadius, borderShadow.CGColor);
    [borderColor setStroke];
    borderPath.lineWidth = 4;
    [borderPath stroke];
    CGContextRestoreGState(context);

    //// Grid Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(CGRectGetMinX(frame) + 102.5, CGRectGetMinY(frame) + 8)];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 102.5, CGRectGetMinY(frame) + 63)];
    [gridLineColor setStroke];
    bezierPath.lineWidth = 1;
    [bezierPath stroke];

    UIBezierPath* bezier2Path = [UIBezierPath bezierPath];
    [bezier2Path moveToPoint: CGPointMake(CGRectGetMinX(frame) + 12, CGRectGetMinY(frame) + 119.5)];
    [bezier2Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 284, CGRectGetMinY(frame) + 119.5)];
    [gridLineColor setStroke];
    bezier2Path.lineWidth = 1;
    [bezier2Path stroke];

    UIBezierPath* bezier4Path = [UIBezierPath bezierPath];
    [bezier4Path moveToPoint: CGPointMake(CGRectGetMinX(frame) + 102.5, CGRectGetMinY(frame) + 120)];
    [bezier4Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 102.5, CGRectGetMinY(frame) + 175)];
    [gridLineColor setStroke];
    bezier4Path.lineWidth = 1;
    [bezier4Path stroke];

    UIBezierPath* bezier5Path = [UIBezierPath bezierPath];
    [bezier5Path moveToPoint: CGPointMake(CGRectGetMinX(frame) + 193.5, CGRectGetMinY(frame) + 120)];
    [bezier5Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 193.5, CGRectGetMinY(frame) + 175)];
    [gridLineColor setStroke];
    bezier5Path.lineWidth = 1;
    [bezier5Path stroke];

    UIBezierPath* bezier3Path = [UIBezierPath bezierPath];
    [bezier3Path moveToPoint: CGPointMake(CGRectGetMinX(frame) + 193.5, CGRectGetMinY(frame) + 8)];
    [bezier3Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 193.5, CGRectGetMinY(frame) + 63)];
    [gridLineColor setStroke];
    bezier3Path.lineWidth = 1;
    [bezier3Path stroke];

    UIBezierPath* bezier6Path = [UIBezierPath bezierPath];
    [bezier6Path moveToPoint: CGPointMake(CGRectGetMinX(frame) + 12, CGRectGetMinY(frame) + 63.5)];
    [bezier6Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 284, CGRectGetMinY(frame) + 63.5)];
    [gridLineColor setStroke];
    bezier6Path.lineWidth = 1;
    [bezier6Path stroke];

    UIBezierPath* bezier7Path = [UIBezierPath bezierPath];
    [bezier7Path moveToPoint: CGPointMake(CGRectGetMinX(frame) + 102.5, CGRectGetMinY(frame) + 64)];
    [bezier7Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 102.5, CGRectGetMinY(frame) + 119)];
    [gridLineColor setStroke];
    bezier7Path.lineWidth = 1;
    [bezier7Path stroke];
    
    UIBezierPath* bezier8Path = [UIBezierPath bezierPath];
    [bezier8Path moveToPoint: CGPointMake(CGRectGetMinX(frame) + 102.5, CGRectGetMinY(frame) + 176)];
    [bezier8Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 102.5, CGRectGetMinY(frame) + 231)];
    [gridLineColor setStroke];
    bezier8Path.lineWidth = 1;
    [bezier8Path stroke];
    
    UIBezierPath* bezier9Path = [UIBezierPath bezierPath];
    [bezier9Path moveToPoint: CGPointMake(CGRectGetMinX(frame) + 193.5, CGRectGetMinY(frame) + 176)];
    [bezier9Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 193.5, CGRectGetMinY(frame) + 231)];
    [gridLineColor setStroke];
    bezier9Path.lineWidth = 1;
    [bezier9Path stroke];
    
    UIBezierPath* bezier10Path = [UIBezierPath bezierPath];
    [bezier10Path moveToPoint: CGPointMake(CGRectGetMinX(frame) + 193.5, CGRectGetMinY(frame) + 64)];
    [bezier10Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 193.5, CGRectGetMinY(frame) + 119)];
    [gridLineColor setStroke];
    bezier10Path.lineWidth = 1;
    [bezier10Path stroke];
    
    UIBezierPath* bezier11Path = [UIBezierPath bezierPath];
    [bezier11Path moveToPoint: CGPointMake(CGRectGetMinX(frame) + 12, CGRectGetMinY(frame) + 175.5)];
    [bezier11Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 287, CGRectGetMinY(frame) + 175.5)];
    [gridLineColor setStroke];
    bezier11Path.lineWidth = 1;
    [bezier11Path stroke];
    
    //// Cleanup
    CGGradientRelease(keyNormalGradient);
    CGGradientRelease(keyHighlightGradient);
    CGColorSpaceRelease(colorSpace);
}


#pragma mark - UI Actions

- (IBAction)keyPressAction:(id)sender
{
    KeypadKey   key = 0;

    key = (sender == self.key1Button)    ? KeypadKey1    : key;
    key = (sender == self.key2Button)    ? KeypadKey2    : key;
    key = (sender == self.key3Button)    ? KeypadKey3    : key;
    key = (sender == self.key4Button)    ? KeypadKey4    : key;
    key = (sender == self.key5Button)    ? KeypadKey5    : key;
    key = (sender == self.key6Button)    ? KeypadKey6    : key;
    key = (sender == self.key7Button)    ? KeypadKey7    : key;
    key = (sender == self.key8Button)    ? KeypadKey8    : key;
    key = (sender == self.key9Button)    ? KeypadKey9    : key;
    key = (sender == self.keyStarButton) ? KeypadKeyStar : key;
    key = (sender == self.key0Button)    ? KeypadKey0    : key;
    key = (sender == self.keyHashButton) ? KeypadKeyHash : key;

    // The key buttons were tagged in the XIB.
    for (int tag = 1; tag <= 12; tag++)
    {
        if (tag != [sender tag])
        {
            ((UIButton*)[self.view viewWithTag:tag]).userInteractionEnabled = NO;
        }
    }

    [self.delegate callKeypadView:self pressedDigitKey:key];
}


- (IBAction)keyReleaseAction:(id)sender
{
    for (int tag = 1; tag <= 12; tag++)
    {
        ((UIButton*)[self.view viewWithTag:tag]).userInteractionEnabled = YES;
    }
}

@end
