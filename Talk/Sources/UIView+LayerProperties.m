//
//  UIView+LayerProperties.m
//  Talk
//
//  Created by Cornelis van der Bent on 08/12/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import "UIView+LayerProperties.h"


IB_DESIGNABLE
@implementation UIView (LayerProperties)

- (CGFloat)borderWidth;
{
    return self.layer.borderWidth;
}


- (void)setBorderWidth:(CGFloat)borderWidth;
{
    self.layer.borderWidth = borderWidth;
}


- (void)setBorderColor:(UIColor*)borderColor
{
    self.layer.borderColor = borderColor.CGColor;
}


- (UIColor*)borderColor;
{
    return [UIColor colorWithCGColor: self.layer.borderColor];
}


- (CGFloat)cornerRadius;
{
    return self.layer.cornerRadius;
}


- (void)setCornerRadius:(CGFloat)cornerRadius;
{
    self.layer.cornerRadius = cornerRadius;
}


- (void)setLayerBackgroundColor:(UIColor*)layerBackgroundColor
{
    self.layer.backgroundColor = layerBackgroundColor.CGColor;
}


- (UIColor*)layerBackgroundColor;
{
    return [UIColor colorWithCGColor: self.layer.backgroundColor];
}

@end
