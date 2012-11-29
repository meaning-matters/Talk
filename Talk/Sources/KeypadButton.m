//
//  KeypadButton.m
//  Talk
//
//  Created by Cornelis van der Bent on 13/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "KeypadButton.h"
#import "Common.h"

@implementation KeypadButton


- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
    }

    return self;
}


- (void)setHighlighted:(BOOL)highlighted
{
    if (self.isHighlighted != highlighted)
    {
        [super setHighlighted:highlighted];

        // Trigger drawRect.
        [self setNeedsDisplay];
    }
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    [self setNeedsDisplay];
}


- (NSString*)keyTitle
{
    switch (self.tag)
    {
        case  1: return @"1";
        case  2: return @"2";
        case  3: return @"3";
        case  4: return @"4";
        case  5: return @"5";
        case  6: return @"6";
        case  7: return @"7";
        case  8: return @"8";
        case  9: return @"9";
        case 10: return @"*";
        case 11: return @"0";
        case 12: return @"#";
        default: return @"";
    }
}


- (NSString*)keySubtitle
{
    switch (self.tag)
    {
        case  1: return @"";
        case  2: return @"ABC";
        case  3: return @"DEF";
        case  4: return @"GHI";
        case  5: return @"JKL";
        case  6: return @"MNO";
        case  7: return @"PQRS";
        case  8: return @"TUV";
        case  9: return @"WXYZ";
        case 10: return @"";
        case 11: return @"+";
        case 12: return @"";
        default: return @"";
    }
}


- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

    // Code below was generated by PaintCode: External/PaintCode/KeypadKey.
    // Note that output of different parts were combined.

    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();

    //// Color Declarations
    UIColor* digitGradientTop = [UIColor colorWithRed: 0.9 green: 0.9 blue: 0.9 alpha: 1];
    UIColor* highlightGradientTop = [UIColor colorWithRed: 0.208 green: 0.497 blue: 1 alpha: 1];
    UIColor* hightlightGradientBottom = [UIColor colorWithRed: 0.551 green: 0.713 blue: 0.997 alpha: 1];
    UIColor* callGradientTop = [UIColor colorWithRed: 0.279 green: 0.7 blue: 0.42 alpha: 1];
    UIColor* callGradientBottom = [UIColor colorWithRed: 0.406 green: 0.983 blue: 0.604 alpha: 1];
    UIColor* callHightlightGradientBottom = [UIColor colorWithRed: 0.321 green: 0.802 blue: 0.481 alpha: 1];
    UIColor* callHightlightGradientTop = [UIColor colorWithRed: 0.199 green: 0.5 blue: 0.299 alpha: 1];
    UIColor* optionEraseGradientTop = [UIColor colorWithRed: 0.80 green: 0.80 blue: 0.80 alpha: 1];
    UIColor* optionEraseGradientBottom = [UIColor colorWithRed: 0.98 green: 0.98 blue: 0.98 alpha: 1];
    UIColor* optionEraseHightlightGradientTop = [UIColor colorWithRed: 0.476 green: 0.476 blue: 0.476 alpha: 1];
    UIColor* optionEraseHightlightGradientBottom = [UIColor colorWithRed: 0.919 green: 0.919 blue: 0.919 alpha: 1];

    //// Gradient Declarations
    NSArray* digitGradientColors = [NSArray arrayWithObjects:
                                    (id)[UIColor whiteColor].CGColor,
                                    (id)[UIColor colorWithRed: 0.95 green: 0.95 blue: 0.95 alpha: 1].CGColor,
                                    (id)digitGradientTop.CGColor, nil];
    CGFloat digitGradientLocations[] = {0, 0.49, 1};
    CGGradientRef digitGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)digitGradientColors, digitGradientLocations);

    NSArray* highlightGradientColors = [NSArray arrayWithObjects:
                                        (id)hightlightGradientBottom.CGColor,
                                        (id)[UIColor colorWithRed: 0.391 green: 0.607 blue: 0.999 alpha: 1].CGColor,
                                        (id)highlightGradientTop.CGColor, nil];
    CGFloat highlightGradientLocations[] = {0, 0.49, 1};
    CGGradientRef highlightGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)highlightGradientColors, highlightGradientLocations);

    NSArray* callGradientColors = [NSArray arrayWithObjects:
                                   (id)callGradientBottom.CGColor,
                                   (id)[UIColor colorWithRed: 0.344 green: 0.845 blue: 0.515 alpha: 1].CGColor,
                                   (id)callGradientTop.CGColor, nil];
    CGFloat callGradientLocations[] = {0, 0.5, 1};
    CGGradientRef callGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)callGradientColors, callGradientLocations);

    NSArray* callHightlightGradientColors = [NSArray arrayWithObjects:
                                             (id)callHightlightGradientBottom.CGColor,
                                             (id)callHightlightGradientTop.CGColor, nil];
    CGFloat callHightlightGradientLocations[] = {0.01, 1};
    CGGradientRef callHightlightGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)callHightlightGradientColors, callHightlightGradientLocations);

    NSArray* optionEraseGradientColors = [NSArray arrayWithObjects:
                                          (id)optionEraseGradientBottom.CGColor,
                                          (id)optionEraseGradientTop.CGColor, nil];
    CGFloat optionEraseGradientLocations[] = {0, 1};
    CGGradientRef optionEraseGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)optionEraseGradientColors, optionEraseGradientLocations);

    NSArray* optionEraseHightlightGradientColors = [NSArray arrayWithObjects:
                                                    (id)optionEraseHightlightGradientBottom.CGColor,
                                                    (id)optionEraseHightlightGradientTop.CGColor, nil];
    CGFloat optionEraseHightlightGradientLocations[] = {0, 1};
    CGGradientRef optionEraseHightlightGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)optionEraseHightlightGradientColors, optionEraseHightlightGradientLocations);

    CGGradientRef   gradient = nil;
    if (1 <= self.tag && self.tag <= 12)
    {
        gradient = (self.state == UIControlStateHighlighted) ? highlightGradient : digitGradient;
    }
    else if (self.tag == 13 || self.tag == 15)
    {
        gradient = (self.state == UIControlStateHighlighted) ? optionEraseHightlightGradient : optionEraseGradient;
    }
    else if (self.tag == 14)
    {
        gradient = (self.state == UIControlStateHighlighted) ? callHightlightGradient : callGradient;
    }

    //// Frames
    CGRect keyFrame = self.bounds;

    //// Subframes
    CGRect innerFrame = CGRectMake(CGRectGetMinX(keyFrame) + floor((CGRectGetWidth(keyFrame) - 41) * 0.49231 + 0.5), CGRectGetMinY(keyFrame) + floor((CGRectGetHeight(keyFrame) - 47) * 0.50000 + 0.5), 41, 47);

    //// Abstracted Attributes
    CGRect keyRect = CGRectMake(CGRectGetMinX(keyFrame) + 0.5, CGRectGetMinY(keyFrame) + 0.5, CGRectGetWidth(keyFrame) - 1, CGRectGetHeight(keyFrame) - 1);
    NSString* titleContent = [self keyTitle];
    NSString* subtitleContent = [self keySubtitle];
    NSString* optionContent = (self.tag == 13) ? @"⚛" : @"";

    //// Key Drawing
    UIBezierPath* keyPath = [UIBezierPath bezierPathWithRect: keyRect];
    CGContextSaveGState(context);
    [keyPath addClip];
    CGContextDrawLinearGradient(context, gradient,
                                CGPointMake(CGRectGetMidX(keyRect), CGRectGetMaxY(keyRect)),
                                CGPointMake(CGRectGetMidX(keyRect), CGRectGetMinY(keyRect)),
                                0);
    CGContextRestoreGState(context);
    [[UIColor grayColor] setStroke];
    keyPath.lineWidth = 1;
    [keyPath stroke];

    if (1 <= self.tag && self.tag <= 12)
    {
        //// Title Drawing
        CGRect titleRect = CGRectMake(CGRectGetMinX(innerFrame) + 1, CGRectGetMinY(innerFrame) + 2, 41, 46);
        (self.state == UIControlStateHighlighted) ? [[UIColor whiteColor] setFill] : [[UIColor blackColor] setFill];
        [titleContent drawInRect: titleRect withFont: [Common phoneFontOfSize: 34] lineBreakMode: NSLineBreakByWordWrapping alignment: NSTextAlignmentCenter];

        //// Subtitle Drawing
        CGRect subtitleRect = CGRectMake(CGRectGetMinX(innerFrame) - 5, CGRectGetMinY(innerFrame) + 33, 53, 15);
        (self.state == UIControlStateHighlighted) ? [[UIColor whiteColor] setFill] : [[UIColor darkGrayColor] setFill];
        [subtitleContent drawInRect: subtitleRect withFont: [Common phoneFontOfSize: [UIFont systemFontSize]] lineBreakMode: NSLineBreakByWordWrapping alignment: NSTextAlignmentCenter];
    }
    else if (self.tag == 13)
    {
        //// Option Drawing
        CGRect optionRect = CGRectMake(CGRectGetMinX(innerFrame) + 0.5, CGRectGetMinY(innerFrame) - 2.5, 28, 51);
        (self.state == UIControlStateHighlighted) ? [[UIColor whiteColor] setFill] : [[UIColor blackColor] setFill];
        [optionContent drawInRect: optionRect withFont: [UIFont fontWithName: @"Helvetica" size: 44] lineBreakMode: NSLineBreakByWordWrapping alignment: NSTextAlignmentCenter];
    }
    else if (self.tag == 14)
    {
        //// Phone Drawing
        UIBezierPath* phonePath = [UIBezierPath bezierPath];
        [phonePath moveToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 12.55, CGRectGetMinY(innerFrame) + 4.17)];
        [phonePath addLineToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 11.68, CGRectGetMinY(innerFrame) + 3.5)];
        [phonePath addLineToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 7.95, CGRectGetMinY(innerFrame) + 3.5)];
        [phonePath addCurveToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 3.92, CGRectGetMinY(innerFrame) + 8.47) controlPoint1: CGPointMake(CGRectGetMinX(innerFrame) + 7.95, CGRectGetMinY(innerFrame) + 3.5) controlPoint2: CGPointMake(CGRectGetMinX(innerFrame) + 5.12, CGRectGetMinY(innerFrame) + 4.35)];
        [phonePath addCurveToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 3.92, CGRectGetMinY(innerFrame) + 15.56) controlPoint1: CGPointMake(CGRectGetMinX(innerFrame) + 2.72, CGRectGetMinY(innerFrame) + 12.59) controlPoint2: CGPointMake(CGRectGetMinX(innerFrame) + 3.92, CGRectGetMinY(innerFrame) + 15.56)];
        [phonePath addCurveToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 3.92, CGRectGetMinY(innerFrame) + 15.56) controlPoint1: CGPointMake(CGRectGetMinX(innerFrame) + 3.92, CGRectGetMinY(innerFrame) + 15.56) controlPoint2: CGPointMake(CGRectGetMinX(innerFrame) + 3.8, CGRectGetMinY(innerFrame) + 14.84)];
        [phonePath addCurveToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 12.55, CGRectGetMinY(innerFrame) + 31.97) controlPoint1: CGPointMake(CGRectGetMinX(innerFrame) + 4.41, CGRectGetMinY(innerFrame) + 18.44) controlPoint2: CGPointMake(CGRectGetMinX(innerFrame) + 7.69, CGRectGetMinY(innerFrame) + 26.78)];
        [phonePath addCurveToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 27.49, CGRectGetMinY(innerFrame) + 42.35) controlPoint1: CGPointMake(CGRectGetMinX(innerFrame) + 17.77, CGRectGetMinY(innerFrame) + 37.56) controlPoint2: CGPointMake(CGRectGetMinX(innerFrame) + 24.29, CGRectGetMinY(innerFrame) + 41.67)];
        [phonePath addCurveToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 34.68, CGRectGetMinY(innerFrame) + 42.02) controlPoint1: CGPointMake(CGRectGetMinX(innerFrame) + 30.7, CGRectGetMinY(innerFrame) + 43.04) controlPoint2: CGPointMake(CGRectGetMinX(innerFrame) + 32.46, CGRectGetMinY(innerFrame) + 42.89)];
        [phonePath addCurveToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 38.99, CGRectGetMinY(innerFrame) + 38.67) controlPoint1: CGPointMake(CGRectGetMinX(innerFrame) + 36.32, CGRectGetMinY(innerFrame) + 41.38) controlPoint2: CGPointMake(CGRectGetMinX(innerFrame) + 38.12, CGRectGetMinY(innerFrame) + 39.71)];
        [phonePath addCurveToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 39.86, CGRectGetMinY(innerFrame) + 36.99) controlPoint1: CGPointMake(CGRectGetMinX(innerFrame) + 39.31, CGRectGetMinY(innerFrame) + 38.3) controlPoint2: CGPointMake(CGRectGetMinX(innerFrame) + 39.86, CGRectGetMinY(innerFrame) + 36.99)];
        [phonePath addCurveToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 39.57, CGRectGetMinY(innerFrame) + 32.31) controlPoint1: CGPointMake(CGRectGetMinX(innerFrame) + 39.86, CGRectGetMinY(innerFrame) + 36.99) controlPoint2: CGPointMake(CGRectGetMinX(innerFrame) + 40.33, CGRectGetMinY(innerFrame) + 32.7)];
        [phonePath addCurveToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 36.98, CGRectGetMinY(innerFrame) + 30.97) controlPoint1: CGPointMake(CGRectGetMinX(innerFrame) + 38.81, CGRectGetMinY(innerFrame) + 31.91) controlPoint2: CGPointMake(CGRectGetMinX(innerFrame) + 36.98, CGRectGetMinY(innerFrame) + 30.97)];
        [phonePath addLineToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 32.09, CGRectGetMinY(innerFrame) + 28.29)];
        [phonePath addLineToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 30.66, CGRectGetMinY(innerFrame) + 28.29)];
        [phonePath addCurveToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 27.49, CGRectGetMinY(innerFrame) + 32.31) controlPoint1: CGPointMake(CGRectGetMinX(innerFrame) + 30.66, CGRectGetMinY(innerFrame) + 28.29) controlPoint2: CGPointMake(CGRectGetMinX(innerFrame) + 28.12, CGRectGetMinY(innerFrame) + 31.46)];
        [phonePath addCurveToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 25.48, CGRectGetMinY(innerFrame) + 33.31) controlPoint1: CGPointMake(CGRectGetMinX(innerFrame) + 26.87, CGRectGetMinY(innerFrame) + 33.15) controlPoint2: CGPointMake(CGRectGetMinX(innerFrame) + 25.48, CGRectGetMinY(innerFrame) + 33.31)];
        [phonePath addCurveToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 18.58, CGRectGetMinY(innerFrame) + 28.29) controlPoint1: CGPointMake(CGRectGetMinX(innerFrame) + 25.48, CGRectGetMinY(innerFrame) + 33.31) controlPoint2: CGPointMake(CGRectGetMinX(innerFrame) + 21.77, CGRectGetMinY(innerFrame) + 31.27)];
        [phonePath addCurveToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 13.12, CGRectGetMinY(innerFrame) + 20.92) controlPoint1: CGPointMake(CGRectGetMinX(innerFrame) + 15.4, CGRectGetMinY(innerFrame) + 25.3) controlPoint2: CGPointMake(CGRectGetMinX(innerFrame) + 13.12, CGRectGetMinY(innerFrame) + 20.92)];
        [phonePath addLineToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 13.26, CGRectGetMinY(innerFrame) + 19.07)];
        [phonePath addCurveToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 15.71, CGRectGetMinY(innerFrame) + 15.89) controlPoint1: CGPointMake(CGRectGetMinX(innerFrame) + 13.26, CGRectGetMinY(innerFrame) + 19.07) controlPoint2: CGPointMake(CGRectGetMinX(innerFrame) + 15.77, CGRectGetMinY(innerFrame) + 15.89)];
        [phonePath addCurveToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 16.28, CGRectGetMinY(innerFrame) + 13.88) controlPoint1: CGPointMake(CGRectGetMinX(innerFrame) + 15.64, CGRectGetMinY(innerFrame) + 15.89) controlPoint2: CGPointMake(CGRectGetMinX(innerFrame) + 16.28, CGRectGetMinY(innerFrame) + 13.88)];
        [phonePath addLineToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 12.55, CGRectGetMinY(innerFrame) + 4.17)];
        [phonePath closePath];
        [[UIColor whiteColor] setFill];
        [phonePath fill];
    }
    else if (self.tag == 15)
    {
        //// Erase Drawing
        UIBezierPath* erasePath = [UIBezierPath bezierPath];
        [erasePath moveToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 15.55, CGRectGetMinY(innerFrame) + 16.43)];
        [erasePath addLineToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 13.43, CGRectGetMinY(innerFrame) + 18.55)];
        [erasePath addLineToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 18.38, CGRectGetMinY(innerFrame) + 23.5)];
        [erasePath addLineToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 13.43, CGRectGetMinY(innerFrame) + 28.45)];
        [erasePath addLineToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 15.55, CGRectGetMinY(innerFrame) + 30.57)];
        [erasePath addLineToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 20.5, CGRectGetMinY(innerFrame) + 25.62)];
        [erasePath addLineToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 25.45, CGRectGetMinY(innerFrame) + 30.57)];
        [erasePath addLineToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 27.57, CGRectGetMinY(innerFrame) + 28.45)];
        [erasePath addLineToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 22.62, CGRectGetMinY(innerFrame) + 23.5)];
        [erasePath addLineToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 27.57, CGRectGetMinY(innerFrame) + 18.55)];
        [erasePath addLineToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 25.45, CGRectGetMinY(innerFrame) + 16.43)];
        [erasePath addLineToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 20.5, CGRectGetMinY(innerFrame) + 21.38)];
        [erasePath addLineToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 15.55, CGRectGetMinY(innerFrame) + 16.43)];
        [erasePath closePath];
        [erasePath moveToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 31, CGRectGetMinY(innerFrame) + 17)];
        [erasePath addLineToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 31, CGRectGetMinY(innerFrame) + 30)];
        [erasePath addCurveToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 27, CGRectGetMinY(innerFrame) + 34) controlPoint1: CGPointMake(CGRectGetMinX(innerFrame) + 31, CGRectGetMinY(innerFrame) + 32.21) controlPoint2: CGPointMake(CGRectGetMinX(innerFrame) + 29.21, CGRectGetMinY(innerFrame) + 34)];
        [erasePath addLineToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 14, CGRectGetMinY(innerFrame) + 34)];
        [erasePath addCurveToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 12.29, CGRectGetMinY(innerFrame) + 33.62) controlPoint1: CGPointMake(CGRectGetMinX(innerFrame) + 13.39, CGRectGetMinY(innerFrame) + 34) controlPoint2: CGPointMake(CGRectGetMinX(innerFrame) + 12.81, CGRectGetMinY(innerFrame) + 33.86)];
        [erasePath addCurveToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 10.71, CGRectGetMinY(innerFrame) + 32.79) controlPoint1: CGPointMake(CGRectGetMinX(innerFrame) + 11.71, CGRectGetMinY(innerFrame) + 33.5) controlPoint2: CGPointMake(CGRectGetMinX(innerFrame) + 11.16, CGRectGetMinY(innerFrame) + 33.22)];
        [erasePath addLineToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 3.26, CGRectGetMinY(innerFrame) + 25.69)];
        [erasePath addCurveToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 3.26, CGRectGetMinY(innerFrame) + 21.31) controlPoint1: CGPointMake(CGRectGetMinX(innerFrame) + 1.99, CGRectGetMinY(innerFrame) + 24.48) controlPoint2: CGPointMake(CGRectGetMinX(innerFrame) + 1.99, CGRectGetMinY(innerFrame) + 22.52)];
        [erasePath addLineToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 10.71, CGRectGetMinY(innerFrame) + 14.21)];
        [erasePath addCurveToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 12.29, CGRectGetMinY(innerFrame) + 13.38) controlPoint1: CGPointMake(CGRectGetMinX(innerFrame) + 11.16, CGRectGetMinY(innerFrame) + 13.78) controlPoint2: CGPointMake(CGRectGetMinX(innerFrame) + 11.71, CGRectGetMinY(innerFrame) + 13.5)];
        [erasePath addCurveToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 14, CGRectGetMinY(innerFrame) + 13) controlPoint1: CGPointMake(CGRectGetMinX(innerFrame) + 12.81, CGRectGetMinY(innerFrame) + 13.14) controlPoint2: CGPointMake(CGRectGetMinX(innerFrame) + 13.39, CGRectGetMinY(innerFrame) + 13)];
        [erasePath addLineToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 27, CGRectGetMinY(innerFrame) + 13)];
        [erasePath addCurveToPoint: CGPointMake(CGRectGetMinX(innerFrame) + 31, CGRectGetMinY(innerFrame) + 17) controlPoint1: CGPointMake(CGRectGetMinX(innerFrame) + 29.21, CGRectGetMinY(innerFrame) + 13) controlPoint2: CGPointMake(CGRectGetMinX(innerFrame) + 31, CGRectGetMinY(innerFrame) + 14.79)];
        [erasePath closePath];
        (self.state == UIControlStateHighlighted) ? [[UIColor whiteColor] setFill] : [[UIColor blackColor] setFill];
        [erasePath fill];
    }

    //// Cleanup
    CGGradientRelease(digitGradient);
    CGGradientRelease(highlightGradient);
    CGGradientRelease(callGradient);
    CGGradientRelease(callHightlightGradient);
    CGGradientRelease(optionEraseGradient);
    CGGradientRelease(optionEraseHightlightGradient);
    CGColorSpaceRelease(colorSpace);    
}

@end
