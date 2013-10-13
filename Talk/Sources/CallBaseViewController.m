//
//  CallBaseViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 12/10/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "CallBaseViewController.h"
#import "Common.h"
#import "UIView+AnimateHidden.h"


@interface CallBaseViewController ()

@end


@implementation CallBaseViewController

- (instancetype)init
{
    if (self = [super initWithNibName:@"CallView" bundle:nil])
    {
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    // Clear backgrounds that are only handy for UI design.
    self.topView.backgroundColor        = [UIColor clearColor];
    self.centerRootView.backgroundColor = [UIColor clearColor];
    self.bottomView.backgroundColor     = [UIColor clearColor];

    [self.calleeLabel setFont:[Common phoneFontOfSize:38]];
    [self.dtmfLabel   setFont:[Common phoneFontOfSize:38]];

    [self drawTopImage];
    [self drawBottomImage];

    [self drawEndButton];
    [self drawHideButton];
    [self drawRetryButton];
    self.hideButton.hidden  = YES;
    self.retryButton.hidden = YES;
}


- (IBAction)endAction:(id)sender
{
}


- (IBAction)hideAction:(id)sender
{
}


- (IBAction)retryAction:(id)sender
{
}


#pragma mark - Utility

- (void)animateView:(UIView*)view fromHidden:(BOOL)fromHide toHidden:(BOOL)toHide
{
    __weak UIView*  weakView = view;

    [weakView setHiddenAnimated:fromHide withDuration:(TransitionDuration / 2) completion:^
    {
        [weakView setHiddenAnimated:toHide withDuration:(TransitionDuration / 2) completion:nil];
    }];
}


- (void)showLargeEndButton
{
    [self showEndButtonWithWidth:280 imageName:@"HangupPhone"];
}


- (void)showSmallEndButton
{
    [self showEndButtonWithWidth:130 imageName:@"HangupPhoneSmall"];
}


- (void)showEndButtonWithWidth:(CGFloat)width imageName:(NSString*)imageName
{
    [self.endButton setHiddenAnimated:YES withDuration:(TransitionDuration / 2) completion:^
    {
        [Common setWidth:width ofView:self.endButton];
        [self drawEndButton];
        [self.endButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
        [self.endButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateHighlighted];

        [self.endButton setHiddenAnimated:NO withDuration:(TransitionDuration / 2) completion:nil];
    }];
}


#pragma mark - Layout

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    switch ((int)self.view.frame.size.height)
    {
        case 460:   // 320x480 screen.
            [Common setY:106 ofView:self.centerRootView];
            [Common setY:367 ofView:self.bottomView];
            break;

        case 440:   // 320x480 screen with in-call iOS flasher at top.
            [Common setY:96  ofView:self.centerRootView];
            [Common setY:347 ofView:self.bottomView];
            break;

        case 548:   // 320x568 screen.
            [Common setY:150 ofView:self.centerRootView];
            [Common setY:455 ofView:self.bottomView];
            break;

        case 528:   // 320x568 screen with in-call iOS flasher at top.
            [Common setY:140 ofView:self.centerRootView];
            [Common setY:435 ofView:self.bottomView];
            break;
    }
}


#pragma mark - Drawing

- (void)drawTopImage
{
    //// Start Image
    UIGraphicsBeginImageContextWithOptions(self.topImageView.frame.size, NO, 0.0);

    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();

    //// Color Declarations
    UIColor* gradientBottomColor = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.8];
    UIColor* gradientTopColor = [UIColor colorWithRed: 0.101 green: 0.101 blue: 0.101 alpha: 0.8];
    UIColor* lineColor = [UIColor colorWithRed: 0.249 green: 0.249 blue: 0.249 alpha: 0.8];

    //// Gradient Declarations
    NSArray* gradientColors = [NSArray arrayWithObjects:
                               (id)gradientTopColor.CGColor,
                               (id)gradientBottomColor.CGColor, nil];
    CGFloat gradientLocations[] = {0, 1};
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)gradientColors, gradientLocations);

    //// Rectangle Drawing
    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: CGRectMake(0, 0, 320, 93)];
    CGContextSaveGState(context);
    [rectanglePath addClip];
    CGContextDrawLinearGradient(context, gradient, CGPointMake(160, -0), CGPointMake(160, 93), 0);
    CGContextRestoreGState(context);

    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(0, 92.5)];
    [bezierPath addLineToPoint: CGPointMake(320, 92.5)];
    [lineColor setStroke];
    bezierPath.lineWidth = 1;
    [bezierPath stroke];

    //// End Image
    UIImage* result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    //// Cleanup
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);

    self.topImageView.image = result;
    [self.topImageView setNeedsDisplay];
}


- (void)drawBottomImage
{
    //// Start Image
    UIGraphicsBeginImageContextWithOptions(self.bottomImageView.frame.size, NO, 0.0);

    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();

    //// Color Declarations
    UIColor* gradientBottomColor = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.8];
    UIColor* gradientTopColor = [UIColor colorWithRed: 0.101 green: 0.101 blue: 0.101 alpha: 0.8];
    UIColor* lineColor = [UIColor colorWithRed: 0.35 green: 0.35 blue: 0.35 alpha: 0.8];

    //// Gradient Declarations
    NSArray* gradientColors = [NSArray arrayWithObjects:
                               (id)gradientTopColor.CGColor,
                               (id)gradientBottomColor.CGColor, nil];
    CGFloat gradientLocations[] = {0, 1};
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)gradientColors, gradientLocations);

    //// Rectangle Drawing
    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: CGRectMake(0, 0, 320, 93)];
    CGContextSaveGState(context);
    [rectanglePath addClip];
    CGContextDrawLinearGradient(context, gradient, CGPointMake(160, -0), CGPointMake(160, 93), 0);
    CGContextRestoreGState(context);

    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(0, 0.5)];
    [bezierPath addLineToPoint: CGPointMake(320, 0.5)];
    [lineColor setStroke];
    bezierPath.lineWidth = 1;
    [bezierPath stroke];

    //// End Image
    UIImage* result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    //// Cleanup
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);

    self.bottomImageView.image = result;
    [self.bottomImageView setNeedsDisplay];
}


- (void)drawEndButton
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    UIColor* normalGradientBottom = [UIColor colorWithRed: 0.802 green: 0.109 blue: 0 alpha: 0.8];
    UIColor* normalGradientTop = [UIColor colorWithRed: 0.799 green: 0.397 blue: 0.397 alpha: 0.8];
    UIColor* highlightGradientTop = [UIColor colorWithRed: 0.502 green: 0.253 blue: 0.257 alpha: 0.8];
    UIColor* highlightGradientBottom = [UIColor colorWithRed: 0.5 green: 0.051 blue: 0 alpha: 0.8];
    UIColor* disableGradientTop = [UIColor colorWithRed: 0.4 green: 0.4 blue: 0.4 alpha: 0.8];
    UIColor* disableGradientBottom = [UIColor colorWithRed: 0.1 green: 0.1 blue: 0.1 alpha: 0.8];

    //// Gradient Declarations
    NSArray* normalGradientColors = [NSArray arrayWithObjects:
                                     (id)normalGradientTop.CGColor,
                                     (id)normalGradientBottom.CGColor, nil];
    CGFloat normalGradientLocations[] = {0, 1};
    CGGradientRef normalGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)normalGradientColors, normalGradientLocations);
    NSArray* highlightGradientColors = [NSArray arrayWithObjects:
                                        (id)highlightGradientTop.CGColor,
                                        (id)highlightGradientBottom.CGColor, nil];
    CGFloat highlightGradientLocations[] = {0, 1};
    CGGradientRef highlightGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)highlightGradientColors, highlightGradientLocations);
    NSArray* disableGradientColors = [NSArray arrayWithObjects:
                                      (id)disableGradientTop.CGColor,
                                      (id)disableGradientBottom.CGColor, nil];
    CGFloat disableGradientLocations[] = {0, 1};
    CGGradientRef disableGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)disableGradientColors, disableGradientLocations);

    UIImage* normalImage = [self drawButtonImageWithGradient:normalGradient size:self.endButton.frame.size];
    UIImage* highlightImage = [self drawButtonImageWithGradient:highlightGradient size:self.endButton.frame.size];
    UIImage* disableImage = [self drawButtonImageWithGradient:disableGradient size:self.endButton.frame.size];

    [self.endButton setBackgroundImage:normalImage forState:UIControlStateNormal];
    [self.endButton setBackgroundImage:highlightImage forState:UIControlStateHighlighted];
    [self.endButton setBackgroundImage:disableImage forState:UIControlStateDisabled];
    [self.endButton setNeedsDisplay];

    //// Cleanup
    CGGradientRelease(normalGradient);
    CGGradientRelease(highlightGradient);
    CGGradientRelease(disableGradient);
    CGColorSpaceRelease(colorSpace);
}


- (void)drawHideButton
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    UIColor* normalGradientTop = [UIColor colorWithRed: 0.4 green: 0.4 blue: 0.4 alpha: 0.8];
    UIColor* normalGradientBottom = [UIColor colorWithRed: 0.1 green: 0.1 blue: 0.1 alpha: 0.8];
    UIColor* highlightGradientBottom = [UIColor colorWithRed: 0 green: 0.373 blue: 1 alpha: 0.8];
    UIColor* highlightGradientTop = [UIColor colorWithRed: 0.203 green: 0.497 blue: 1 alpha: 0.8];

    //// Gradient Declarations
    NSArray* normalGradientColors = [NSArray arrayWithObjects:
                                     (id)normalGradientTop.CGColor,
                                     (id)normalGradientBottom.CGColor, nil];
    CGFloat normalGradientLocations[] = {0, 1};
    CGGradientRef normalGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)normalGradientColors, normalGradientLocations);
    NSArray* highlightGradientColors = [NSArray arrayWithObjects:
                                        (id)highlightGradientTop.CGColor,
                                        (id)highlightGradientBottom.CGColor, nil];
    CGFloat highlightGradientLocations[] = {0, 1};
    CGGradientRef highlightGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)highlightGradientColors, highlightGradientLocations);

    UIImage* normalImage = [self drawButtonImageWithGradient:normalGradient size:self.hideButton.frame.size];
    UIImage* highlightImage = [self drawButtonImageWithGradient:highlightGradient size:self.hideButton.frame.size];

    [self.hideButton setBackgroundImage:normalImage forState:UIControlStateNormal];
    [self.hideButton setBackgroundImage:highlightImage forState:UIControlStateHighlighted];
    [self.hideButton setNeedsDisplay];

    //// Cleanup
    CGGradientRelease(normalGradient);
    CGGradientRelease(highlightGradient);
    CGColorSpaceRelease(colorSpace);
}


- (void)drawRetryButton
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    UIColor* normalGradientTop = [UIColor colorWithRed: 0.4 green: 0.4 blue: 0.4 alpha: 0.8];
    UIColor* normalGradientBottom = [UIColor colorWithRed: 0.1 green: 0.1 blue: 0.1 alpha: 0.8];
    UIColor* highlightGradientBottom = [UIColor colorWithRed: 0 green: 0.373 blue: 1 alpha: 0.8];
    UIColor* highlightGradientTop = [UIColor colorWithRed: 0.203 green: 0.497 blue: 1 alpha: 0.8];

    //// Gradient Declarations
    NSArray* normalGradientColors = [NSArray arrayWithObjects:
                                     (id)normalGradientTop.CGColor,
                                     (id)normalGradientBottom.CGColor, nil];
    CGFloat normalGradientLocations[] = {0, 1};
    CGGradientRef normalGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)normalGradientColors, normalGradientLocations);
    NSArray* highlightGradientColors = [NSArray arrayWithObjects:
                                        (id)highlightGradientTop.CGColor,
                                        (id)highlightGradientBottom.CGColor, nil];
    CGFloat highlightGradientLocations[] = {0, 1};
    CGGradientRef highlightGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)highlightGradientColors, highlightGradientLocations);

    UIImage* normalImage = [self drawButtonImageWithGradient:normalGradient size:self.retryButton.frame.size];
    UIImage* highlightImage = [self drawButtonImageWithGradient:highlightGradient size:self.retryButton.frame.size];

    [self.retryButton setBackgroundImage:normalImage forState:UIControlStateNormal];
    [self.retryButton setBackgroundImage:highlightImage forState:UIControlStateHighlighted];
    [self.retryButton setNeedsDisplay];

    //// Cleanup
    CGGradientRelease(normalGradient);
    CGGradientRelease(highlightGradient);
    CGColorSpaceRelease(colorSpace);
}


- (UIImage*)drawButtonImageWithGradient:(CGGradientRef)gradient size:(CGSize)size
{
    //// Start Image
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);

    //// General Declarations
    CGContextRef context = UIGraphicsGetCurrentContext();

    //// Color Declarations
    UIColor* strokeColor = [UIColor colorWithRed: 0.297 green: 0.297 blue: 0.297 alpha: 0.8];
    UIColor* shadowColor2 = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.8];

    //// Shadow Declarations
    UIColor* innerShadow = shadowColor2;
    CGSize innerShadowOffset = CGSizeMake(0.1, 2.1);
    CGFloat innerShadowBlurRadius = 4;

    //// Abstracted Attributes
    CGRect roundedRectangleRect = CGRectMake(2, 2, size.width - 4.0f, 48);

    //// Rounded Rectangle Drawing
    UIBezierPath* roundedRectanglePath = [UIBezierPath bezierPathWithRoundedRect: roundedRectangleRect cornerRadius: 12];
    CGContextSaveGState(context);
    [roundedRectanglePath addClip];
    CGContextDrawLinearGradient(context, gradient, CGPointMake(65, 2), CGPointMake(65, 50), 0);
    CGContextRestoreGState(context);

    ////// Rounded Rectangle Inner Shadow
    CGRect roundedRectangleBorderRect = CGRectInset([roundedRectanglePath bounds], -innerShadowBlurRadius, -innerShadowBlurRadius);
    roundedRectangleBorderRect = CGRectOffset(roundedRectangleBorderRect, -innerShadowOffset.width, -innerShadowOffset.height);
    roundedRectangleBorderRect = CGRectInset(CGRectUnion(roundedRectangleBorderRect, [roundedRectanglePath bounds]), -1, -1);

    UIBezierPath* roundedRectangleNegativePath = [UIBezierPath bezierPathWithRect: roundedRectangleBorderRect];
    [roundedRectangleNegativePath appendPath: roundedRectanglePath];
    roundedRectangleNegativePath.usesEvenOddFillRule = YES;

    CGContextSaveGState(context);
    {
        CGFloat xOffset = innerShadowOffset.width + round(roundedRectangleBorderRect.size.width);
        CGFloat yOffset = innerShadowOffset.height;
        CGContextSetShadowWithColor(context,
                                    CGSizeMake(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset)),
                                    innerShadowBlurRadius,
                                    innerShadow.CGColor);

        [roundedRectanglePath addClip];
        CGAffineTransform transform = CGAffineTransformMakeTranslation(-round(roundedRectangleBorderRect.size.width), 0);
        [roundedRectangleNegativePath applyTransform: transform];
        [[UIColor grayColor] setFill];
        [roundedRectangleNegativePath fill];
    }
    CGContextRestoreGState(context);

    [strokeColor setStroke];
    roundedRectanglePath.lineWidth = 4;
    [roundedRectanglePath stroke];
    
    //// End Image
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
