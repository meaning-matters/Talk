//
//  CallKeypadView.m
//  Talk
//
//  Created by Cornelis van der Bent on 29/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "CallKeypadView.h"

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
    UIColor* borderColor = [UIColor colorWithRed: 0.318 green: 0.318 blue: 0.318 alpha: 0.5];
    UIColor* girdLine = [UIColor colorWithRed: 0.5 green: 0.5 blue: 0.5 alpha: 0.5];
    UIColor* gradient2Color = [UIColor colorWithRed: 0.901 green: 0.901 blue: 0.901 alpha: 0.5];
    UIColor* gradient2Color2 = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 0.75];

    //// Gradient Declarations
    NSArray* gradient2Colors = [NSArray arrayWithObjects:
                                (id)gradient2Color.CGColor,
                                (id)gradient2Color2.CGColor, nil];
    CGFloat gradient2Locations[] = {0, 1};
    CGGradientRef gradient2 = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)gradient2Colors, gradient2Locations);

    //// Shadow Declarations
    UIColor* shadow = [UIColor blackColor];
    CGSize shadowOffset = CGSizeMake(0.1, -0.1);
    CGFloat shadowBlurRadius = 6;

    //// Frames
    CGRect frame = self.bounds;

    //// Background Drawing
    UIBezierPath* backgroundPath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(CGRectGetMinX(frame) + 9, CGRectGetMinY(frame) + 9, 275, 223) cornerRadius: 10];

    //// Border Drawing
    UIBezierPath* borderPath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(CGRectGetMinX(frame) + 7, CGRectGetMinY(frame) + 7, 279, 227) cornerRadius: 12];
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, shadowOffset, shadowBlurRadius, shadow.CGColor);
    [borderColor setStroke];
    borderPath.lineWidth = 4;
    [borderPath stroke];
    CGContextRestoreGState(context);
    
    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(CGRectGetMinX(frame) + 100.5, CGRectGetMinY(frame) + 9)];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 100.5, CGRectGetMinY(frame) + 64)];
    [girdLine setStroke];
    bezierPath.lineWidth = 1;
    [bezierPath stroke];

    //// Bezier 2 Drawing
    UIBezierPath* bezier2Path = [UIBezierPath bezierPath];
    [bezier2Path moveToPoint: CGPointMake(CGRectGetMinX(frame) + 9, CGRectGetMinY(frame) + 120.5)];
    [bezier2Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 284, CGRectGetMinY(frame) + 120.5)];
    [girdLine setStroke];
    bezier2Path.lineWidth = 1;
    [bezier2Path stroke];

    //// Bezier 4 Drawing
    UIBezierPath* bezier4Path = [UIBezierPath bezierPath];
    [bezier4Path moveToPoint: CGPointMake(CGRectGetMinX(frame) + 100.5, CGRectGetMinY(frame) + 121)];
    [bezier4Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 100.5, CGRectGetMinY(frame) + 176)];
    [girdLine setStroke];
    bezier4Path.lineWidth = 1;
    [bezier4Path stroke];

    //// Bezier 5 Drawing
    UIBezierPath* bezier5Path = [UIBezierPath bezierPath];
    [bezier5Path moveToPoint: CGPointMake(CGRectGetMinX(frame) + 192.5, CGRectGetMinY(frame) + 121)];
    [bezier5Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 192.5, CGRectGetMinY(frame) + 176)];
    [girdLine setStroke];
    bezier5Path.lineWidth = 1;
    [bezier5Path stroke];

    //// Bezier 3 Drawing
    UIBezierPath* bezier3Path = [UIBezierPath bezierPath];
    [bezier3Path moveToPoint: CGPointMake(CGRectGetMinX(frame) + 192.5, CGRectGetMinY(frame) + 9)];
    [bezier3Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 192.5, CGRectGetMinY(frame) + 64)];
    [girdLine setStroke];
    bezier3Path.lineWidth = 1;
    [bezier3Path stroke];

    //// Bezier 6 Drawing
    UIBezierPath* bezier6Path = [UIBezierPath bezierPath];
    [bezier6Path moveToPoint: CGPointMake(CGRectGetMinX(frame) + 9, CGRectGetMinY(frame) + 64.5)];
    [bezier6Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 284, CGRectGetMinY(frame) + 64.5)];
    [girdLine setStroke];
    bezier6Path.lineWidth = 1;
    [bezier6Path stroke];

    //// Bezier 7 Drawing
    UIBezierPath* bezier7Path = [UIBezierPath bezierPath];
    [bezier7Path moveToPoint: CGPointMake(CGRectGetMinX(frame) + 100.5, CGRectGetMinY(frame) + 65)];
    [bezier7Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 100.5, CGRectGetMinY(frame) + 120)];
    [girdLine setStroke];
    bezier7Path.lineWidth = 1;
    [bezier7Path stroke];

    //// Bezier 8 Drawing
    UIBezierPath* bezier8Path = [UIBezierPath bezierPath];
    [bezier8Path moveToPoint: CGPointMake(CGRectGetMinX(frame) + 100.5, CGRectGetMinY(frame) + 177)];
    [bezier8Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 100.5, CGRectGetMinY(frame) + 232)];
    [girdLine setStroke];
    bezier8Path.lineWidth = 1;
    [bezier8Path stroke];

    //// Bezier 9 Drawing
    UIBezierPath* bezier9Path = [UIBezierPath bezierPath];
    [bezier9Path moveToPoint: CGPointMake(CGRectGetMinX(frame) + 192.5, CGRectGetMinY(frame) + 177)];
    [bezier9Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 192.5, CGRectGetMinY(frame) + 232)];
    [girdLine setStroke];
    bezier9Path.lineWidth = 1;
    [bezier9Path stroke];
    
    //// Bezier 10 Drawing
    UIBezierPath* bezier10Path = [UIBezierPath bezierPath];
    [bezier10Path moveToPoint: CGPointMake(CGRectGetMinX(frame) + 192.5, CGRectGetMinY(frame) + 65)];
    [bezier10Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 192.5, CGRectGetMinY(frame) + 120)];
    [girdLine setStroke];
    bezier10Path.lineWidth = 1;
    [bezier10Path stroke];
    
    //// Bezier 11 Drawing
    UIBezierPath* bezier11Path = [UIBezierPath bezierPath];
    [bezier11Path moveToPoint: CGPointMake(CGRectGetMinX(frame) + 9, CGRectGetMinY(frame) + 176.5)];
    [bezier11Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 284, CGRectGetMinY(frame) + 176.5)];
    [girdLine setStroke];
    bezier11Path.lineWidth = 1;
    [bezier11Path stroke];
    
    //// Cleanup
    CGGradientRelease(gradient2);
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
