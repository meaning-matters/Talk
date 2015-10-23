//
//  ShareButton.m
//  Talk
//
//  Created by Cornelis van der Bent on 26/05/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "ShareButton.h"

@implementation ShareButton

- (void)setHighlighted:(BOOL)highlighted
{
    if (self.isHighlighted != highlighted)
    {
        [super setHighlighted:highlighted];

        // Trigger drawRect.
        [self setNeedsDisplay];
    }
}


- (void)drawRect:(CGRect)rect
{
    //// Color Declarations
    UIColor*    fillColor;
    if (self.color != nil)
    {
        fillColor = self.highlighted ? self.color : [UIColor whiteColor];
    }
    else
    {
        fillColor = self.highlighted ? [UIColor colorWithWhite:0.6f alpha:1.0f] : [UIColor whiteColor];
    }
    
    UIColor* strokeColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];

    //// Rounded Rectangle Drawing
    UIBezierPath* roundedRectanglePath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(0.5, 0.5, 79, 79) cornerRadius:12];
    [fillColor setFill];
    [roundedRectanglePath fill];
    [strokeColor setStroke];
    roundedRectanglePath.lineWidth = 1;
    [roundedRectanglePath stroke];
}

@end
