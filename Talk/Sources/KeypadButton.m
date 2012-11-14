//
//  KeypadButton.m
//  Talk
//
//  Created by Cornelis van der Bent on 13/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "KeypadButton.h"

@implementation KeypadButton

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
    }

    return self;
}


- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

    if (self.highlighted)
    {
        //// General Declarations
        CGContextRef context = UIGraphicsGetCurrentContext();

        //// Color Declarations
        UIColor* selectedTextBackgroundColor = [UIColor colorWithRed: 0.71 green: 0.835 blue: 1 alpha: 1];

        //// Shadow Declarations
        UIColor* shadow = [UIColor blackColor];
        CGSize shadowOffset = CGSizeMake(0.1, -0.1);
        CGFloat shadowBlurRadius = 9.5;

        //// Rounded Rectangle Drawing
        UIBezierPath* roundedRectanglePath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(0.5, 0.5, 43, 24) cornerRadius: 9];
        [selectedTextBackgroundColor setFill];
        [roundedRectanglePath fill];

        ////// Rounded Rectangle Inner Shadow
        CGRect roundedRectangleBorderRect = CGRectInset([roundedRectanglePath bounds], -shadowBlurRadius, -shadowBlurRadius);
        roundedRectangleBorderRect = CGRectOffset(roundedRectangleBorderRect, -shadowOffset.width, -shadowOffset.height);
        roundedRectangleBorderRect = CGRectInset(CGRectUnion(roundedRectangleBorderRect, [roundedRectanglePath bounds]), -1, -1);

        UIBezierPath* roundedRectangleNegativePath = [UIBezierPath bezierPathWithRect: roundedRectangleBorderRect];
        [roundedRectangleNegativePath appendPath: roundedRectanglePath];
        roundedRectangleNegativePath.usesEvenOddFillRule = YES;

        CGContextSaveGState(context);
        {
            CGFloat xOffset = shadowOffset.width + round(roundedRectangleBorderRect.size.width);
            CGFloat yOffset = shadowOffset.height;
            CGContextSetShadowWithColor(context,
                                        CGSizeMake(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset)),
                                        shadowBlurRadius,
                                        shadow.CGColor);

            [roundedRectanglePath addClip];
            CGAffineTransform transform = CGAffineTransformMakeTranslation(-round(roundedRectangleBorderRect.size.width), 0);
            [roundedRectangleNegativePath applyTransform: transform];
            [[UIColor grayColor] setFill];
            [roundedRectangleNegativePath fill];
        }
        CGContextRestoreGState(context);
        
        [[UIColor blackColor] setStroke];
        roundedRectanglePath.lineWidth = 1;
        [roundedRectanglePath stroke];
    }
    else
    {
        
    }
}

@end
