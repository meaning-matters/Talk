//
//  CallOptionButton.m
//  Talk
//
//  Created by Cornelis van der Bent on 29/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "CallOptionButton.h"
#import "Common.h"

@implementation CallOptionButton

@synthesize on = _on;


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
        case  1: return NSLocalizedStringWithDefaultValue(@"Call:Options MuteTitle", nil,
                                                          [NSBundle mainBundle], @"mute",
                                                          @"In-call mute button title; Apple standard\n"
                                                          @"[0.2 line small font].");

        case  2: return NSLocalizedStringWithDefaultValue(@"Call:Options KeypadTitle", nil,
                                                          [NSBundle mainBundle], @"keypad",
                                                          @"In-call keypad button title; Apple standard\n"
                                                          @"[0.2 line small font].");

        case  3: return NSLocalizedStringWithDefaultValue(@"Call:Options SpeakerTitle", nil,
                                                          [NSBundle mainBundle], @"speaker",
                                                          @"In-call speaker button title; Apple standard\n"
                                                          @"[0.2 line small font].");

        case  4: return NSLocalizedStringWithDefaultValue(@"Call:Options AddTitle", nil,
                                                          [NSBundle mainBundle], @"add",
                                                          @"In-call add-call button title; Apple standard\n"
                                                          @"[0.2 line small font].");

        case  5: return NSLocalizedStringWithDefaultValue(@"Call:Options HoldTitle", nil,
                                                          [NSBundle mainBundle], @"hold",
                                                          @"In-call hold button title; Apple standard\n"
                                                          @"[0.2 line small font].");

        case  6: return NSLocalizedStringWithDefaultValue(@"Call:Options GroupsTitle", nil,
                                                          [NSBundle mainBundle], @"groups",
                                                          @"In-call groups (wrt contacts) button title; Apple standard\n"
                                                          @"[0.2 line small font].");

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

    CGGradientRef gradient = (self.highlighted || self.on) ? keyHighlightGradient : keyNormalGradient;

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
        case  4: corners = UIRectCornerBottomLeft; break;
        case  6: corners = UIRectCornerBottomRight; break;
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
    CGRect textRect = CGRectMake(CGRectGetMinX(self.bounds) + 3, CGRectGetMinY(self.bounds) + 83, 84, 20);
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, textShadowOffset, textShadowBlurRadius, textShadow.CGColor);
    [[UIColor grayColor] setFill];
    [[self keyTitle] drawInRect: textRect withFont: [Common phoneFontOfSize:13] lineBreakMode: 0 alignment: NSTextAlignmentCenter];
    CGContextRestoreGState(context);

    //// Cleanup
    CGGradientRelease(keyNormalGradient);
    CGGradientRelease(keyHighlightGradient);
    CGColorSpaceRelease(colorSpace);
}


- (void)setOn:(BOOL)on
{
    _on = on;
    [self setNeedsDisplay];
}

@end
