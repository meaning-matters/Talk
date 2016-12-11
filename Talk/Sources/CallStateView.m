//
//  CallStateView.m
//  Talk
//
//  Created by Cornelis van der Bent on 30/11/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import "CallStateView.h"

@implementation CallStateView

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
    // Assumes that the XIB has the exact same name as the subview class.
    [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil];

    CGRect frame    = self.frame;
    self.view.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);

    [self addSubview:self.view];

    self.backgroundColor = [UIColor clearColor];
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
    CGContextRef    context    = UIGraphicsGetCurrentContext();

    //// Color Declarations
    UIColor* centerNormalGradientTop    = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.8];
    UIColor* centerNormalGradientBottom = [UIColor colorWithRed: 0.079 green: 0.079 blue: 0.079 alpha: 0.8];

    //// Gradient Declarations
    NSArray* keyNormalGradientColors = [NSArray arrayWithObjects:
                                        (id)centerNormalGradientTop.CGColor,
                                        (id)centerNormalGradientBottom.CGColor, nil];
    CGFloat keyNormalGradientLocations[] = {0, 0.98};
    CGGradientRef keyNormalGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)keyNormalGradientColors, keyNormalGradientLocations);

    //// Frames
    CGRect frame = CGRectMake(0, 0, 296, 247);

    //// Center Drawing
    CGRect centerRect = CGRectMake(CGRectGetMinX(frame) + 12, CGRectGetMinY(frame) + 12, 272, 223);
    UIBezierPath* centerPath = [UIBezierPath bezierPathWithRoundedRect: centerRect cornerRadius: 5];
    CGContextSaveGState(context);
    [centerPath addClip];
    CGContextDrawLinearGradient(context, keyNormalGradient,
                                CGPointMake(CGRectGetMidX(centerRect), CGRectGetMinY(centerRect)),
                                CGPointMake(CGRectGetMidX(centerRect), CGRectGetMaxY(centerRect)),
                                0);
    CGContextRestoreGState(context);

    //// Cleanup
    CGGradientRelease(keyNormalGradient);
    CGColorSpaceRelease(colorSpace);
}

@end
