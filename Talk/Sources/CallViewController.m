//
//  CallViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 26/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "CallViewController.h"
#import "Common.h"


@interface CallViewController ()
{
    CallOptionsView*    callOptionsView;
    CallKeypadView*     callKeypadView;
}

@end


@implementation CallViewController

@synthesize backgroundImageView = _backgroundImageView;
@synthesize topView             = _topView;
@synthesize centerRootView      = _centerRootView;
@synthesize bottomView          = _bottomView;

@synthesize topImageView        = _topImageView;
@synthesize bottomImageView     = _bottomImageView;


- (id)init
{
    if (self = [super initWithNibName:@"CallView" bundle:nil])
    {
        callKeypadView.delegate = self;
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

    CGRect  frame = CGRectMake(0, 0, self.centerRootView.frame.size.width, self.centerRootView.frame.size.height);
    callOptionsView = [[CallOptionsView alloc] initWithFrame:frame];
    callKeypadView  = [[CallKeypadView alloc] initWithFrame:frame];

    [self.centerRootView addSubview:callOptionsView];

    [self drawTopImage];
    [self drawBottomImage];
}


- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    switch ((int)self.view.frame.size.height)
    {
        case 460:   // 320x480 screen.
            [Common setY:106 ofView:self.centerRootView];
            [Common setY:367 ofView:self.bottomView];
            break;

        case 548:   // 320x568 screen.
            [Common setY:150 ofView:self.centerRootView];
            [Common setY:455 ofView:self.bottomView];
            break;
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - Drawing

- (void)drawTopImage
{
    //// Start Image
    UIGraphicsBeginImageContext(self.topImageView.frame.size);

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


-(void)drawBottomImage
{
    //// Start Image
    UIGraphicsBeginImageContext(self.topImageView.frame.size);

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


#pragma mark - Keypad Delegate

- (void)callKeypadView:(CallKeypadView*)keypadView pressedDigitKey:(KeypadKey)key
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
