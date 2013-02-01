//
//  CallKeypadButton.m
//  Talk
//
//  Created by Cornelis van der Bent on 29/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "CallKeypadButton.h"
#import "Common.h"


@implementation CallKeypadButton

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


- (void)drawRect:(CGRect)rect
{
    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef    context = UIGraphicsGetCurrentContext();

    //// Color Declarations
    UIColor* keyNormalGradientTop = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.8];
    UIColor* keyNormalGradientBottom = [UIColor colorWithRed: 0.103 green: 0.103 blue: 0.102 alpha: 0.8];
    UIColor* keyHighlightGradientColor = [UIColor colorWithRed: 0 green: 0.373 blue: 1 alpha: 0.8];
    UIColor* keyHighlightGradientColor2 = [UIColor colorWithRed: 0.203 green: 0.497 blue: 1 alpha: 0.8];
    UIColor* textShadowColor = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.5];

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

    CGGradientRef gradient = (self.highlighted) ? keyHighlightGradient : keyNormalGradient;

    //// Shadow Declarations
    UIColor* textShadow = textShadowColor;
    CGSize textShadowOffset = CGSizeMake(0.1, 1.1);
    CGFloat textShadowBlurRadius = 1;

    //// Drawing
    UIRectCorner corners;
    switch (self.tag)
    {
        case  1: corners = UIRectCornerTopLeft; break;
        case  3: corners = UIRectCornerTopRight; break;
        case 10: corners = UIRectCornerBottomLeft; break;
        case 12: corners = UIRectCornerBottomRight; break;
        default: corners = 0; break;
    }

    UIBezierPath*   path = [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                               byRoundingCorners:corners
                                                     cornerRadii:CGSizeMake(10, 10)];
    CGContextSaveGState(context);
    [path addClip];
    CGContextDrawLinearGradient(context, gradient,
                                CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMinY(self.bounds)),
                                CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMaxY(self.bounds)),
                                0);
    CGContextRestoreGState(context);

    //// Text Drawing
    CGRect textRect = CGRectMake(CGRectGetMinX(self.bounds) + 21, CGRectGetMinY(self.bounds) + 14, 48, 38);
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, textShadowOffset, textShadowBlurRadius, textShadow.CGColor);
    [[UIColor whiteColor] setFill];
    [[self keyTitle] drawInRect: textRect withFont: [Common phoneFontOfSize:34] lineBreakMode: 0 alignment: NSTextAlignmentCenter];
    CGContextRestoreGState(context);

    //// Cleanup
    CGGradientRelease(keyNormalGradient);
    CGGradientRelease(keyHighlightGradient);
    CGColorSpaceRelease(colorSpace);
}

@end
