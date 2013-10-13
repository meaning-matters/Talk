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

- (instancetype)initWithFrame:(CGRect)frame
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
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 102.5, CGRectGetMinY(frame) + 67)];
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
    [bezier4Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 102.5, CGRectGetMinY(frame) + 179)];
    [gridLineColor setStroke];
    bezier4Path.lineWidth = 1;
    [bezier4Path stroke];

    UIBezierPath* bezier5Path = [UIBezierPath bezierPath];
    [bezier5Path moveToPoint: CGPointMake(CGRectGetMinX(frame) + 193.5, CGRectGetMinY(frame) + 124)];
    [bezier5Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 193.5, CGRectGetMinY(frame) + 179)];
    [gridLineColor setStroke];
    bezier5Path.lineWidth = 1;
    [bezier5Path stroke];

    UIBezierPath* bezier3Path = [UIBezierPath bezierPath];
    [bezier3Path moveToPoint: CGPointMake(CGRectGetMinX(frame) + 193.5, CGRectGetMinY(frame) + 12)];
    [bezier3Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 193.5, CGRectGetMinY(frame) + 67)];
    [gridLineColor setStroke];
    bezier3Path.lineWidth = 1;
    [bezier3Path stroke];

    UIBezierPath* bezier6Path = [UIBezierPath bezierPath];
    [bezier6Path moveToPoint: CGPointMake(CGRectGetMinX(frame) + 12, CGRectGetMinY(frame) + 67.5)];
    [bezier6Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 284, CGRectGetMinY(frame) + 67.5)];
    [gridLineColor setStroke];
    bezier6Path.lineWidth = 1;
    [bezier6Path stroke];

    UIBezierPath* bezier7Path = [UIBezierPath bezierPath];
    [bezier7Path moveToPoint: CGPointMake(CGRectGetMinX(frame) + 102.5, CGRectGetMinY(frame) + 68)];
    [bezier7Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 102.5, CGRectGetMinY(frame) + 123)];
    [gridLineColor setStroke];
    bezier7Path.lineWidth = 1;
    [bezier7Path stroke];

    UIBezierPath* bezier8Path = [UIBezierPath bezierPath];
    [bezier8Path moveToPoint: CGPointMake(CGRectGetMinX(frame) + 102.5, CGRectGetMinY(frame) + 180)];
    [bezier8Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 102.5, CGRectGetMinY(frame) + 235)];
    [gridLineColor setStroke];
    bezier8Path.lineWidth = 1;
    [bezier8Path stroke];

    UIBezierPath* bezier9Path = [UIBezierPath bezierPath];
    [bezier9Path moveToPoint: CGPointMake(CGRectGetMinX(frame) + 193.5, CGRectGetMinY(frame) + 180)];
    [bezier9Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 193.5, CGRectGetMinY(frame) + 235)];
    [gridLineColor setStroke];
    bezier9Path.lineWidth = 1;
    [bezier9Path stroke];

    UIBezierPath* bezier10Path = [UIBezierPath bezierPath];
    [bezier10Path moveToPoint: CGPointMake(CGRectGetMinX(frame) + 193.5, CGRectGetMinY(frame) + 68)];
    [bezier10Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 193.5, CGRectGetMinY(frame) + 123)];
    [gridLineColor setStroke];
    bezier10Path.lineWidth = 1;
    [bezier10Path stroke];

    UIBezierPath* bezier11Path = [UIBezierPath bezierPath];
    [bezier11Path moveToPoint: CGPointMake(CGRectGetMinX(frame) + 12, CGRectGetMinY(frame) + 179.5)];
    [bezier11Path addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 284, CGRectGetMinY(frame) + 179.5)];
    [gridLineColor setStroke];
    bezier11Path.lineWidth = 1;
    [bezier11Path stroke];

    //// Cleanup
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
