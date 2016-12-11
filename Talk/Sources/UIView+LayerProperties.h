//
//  UIView+LayerProperties.h
//  Talk
//
//  Created by Cornelis van der Bent on 08/12/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface UIView (LayerProperties)

@property (nonatomic, assign) IBInspectable CGFloat  borderWidth;
@property (nonatomic, strong) IBInspectable UIColor* borderColor;
@property (nonatomic, assign) IBInspectable CGFloat  cornerRadius;
@property (nonatomic, strong) IBInspectable UIColor* layerBackgroundColor;

@end
