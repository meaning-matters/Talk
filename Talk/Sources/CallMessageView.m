//
//  CallMessageView.m
//  Talk
//
//  Created by Cornelis van der Bent on 23/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "CallMessageView.h"

@implementation CallMessageView

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
    [[NSBundle mainBundle] loadNibNamed:@"CallMessageView" owner:self options:nil];
    CGRect frame = self.frame;
    self.view.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    [self addSubview:self.view];

    self.backgroundColor = [UIColor clearColor];
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
    UIColor* centerNormalGradientTop = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.8];
    UIColor* centerNormalGradientBottom = [UIColor colorWithRed: 0.103 green: 0.103 blue: 0.103 alpha: 0.8];
    UIColor* borderShadowColor = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.5];

    //// Gradient Declarations
    NSArray* keyNormalGradientColors = [NSArray arrayWithObjects:
                                        (id)centerNormalGradientTop.CGColor,
                                        (id)centerNormalGradientBottom.CGColor, nil];
    CGFloat keyNormalGradientLocations[] = {0, 0.98};
    CGGradientRef keyNormalGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)keyNormalGradientColors, keyNormalGradientLocations);

    //// Shadow Declarations
    UIColor* borderShadow = borderShadowColor;
    CGSize borderShadowOffset = CGSizeMake(0.1, 2.1);
    CGFloat borderShadowBlurRadius = 4;

    //// Frames
    CGRect frame = CGRectMake(0, 0, 296, 247);


    //// Border Drawing
    UIBezierPath* borderPath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(CGRectGetMinX(frame) + 10, CGRectGetMinY(frame) + 10, 276, 227) cornerRadius: 12];
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, borderShadowOffset, borderShadowBlurRadius, borderShadow.CGColor);
    [borderColor setStroke];
    borderPath.lineWidth = 4;
    [borderPath stroke];
    CGContextRestoreGState(context);


    //// Center Drawing
    CGRect centerRect = CGRectMake(CGRectGetMinX(frame) + 12, CGRectGetMinY(frame) + 12, 272, 223);
    UIBezierPath* centerPath = [UIBezierPath bezierPathWithRoundedRect: centerRect cornerRadius: 10];
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
