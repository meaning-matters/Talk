//
//  UIViewController+Common.m
//  Talk
//
//  Created by Cornelis van der Bent on 04/01/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//
//  http://nshipster.com/method-swizzling/

#import <objc/runtime.h>
#import "UIViewController+Common.h"


@implementation UIViewController (Common)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        Class class = [self class];

        SEL originalSelector = @selector(viewWillLayoutSubviews);
        SEL swizzledSelector = @selector(viewWillLayoutSubviewsSwizzled);

        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

        BOOL didAddMethod = class_addMethod(class,
                                            originalSelector,
                                            method_getImplementation(swizzledMethod),
                                            method_getTypeEncoding(swizzledMethod));

        if (didAddMethod)
        {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        }
        else
        {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}


#pragma mark - Properties

- (UIActivityIndicatorView*)activityIndicator
{
    return objc_getAssociatedObject(self, @selector(activityIndicator));
}


- (void)setActivityIndicator:(UIActivityIndicatorView*)activityIndicator
{
    objc_setAssociatedObject(self,
                             @selector(activityIndicator),
                             activityIndicator,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (UIImageView*)imageView
{
    return  objc_getAssociatedObject(self, @selector(imageView));
}


- (void)setImageView:(UIImageView*)imageView
{
    objc_setAssociatedObject(self,
                             @selector(imageView),
                             imageView,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (BOOL)hasCenteredActivityIndicator
{
    return [objc_getAssociatedObject(self, @selector(hasCenteredActivityIndicator)) boolValue];
}


- (void)setHasCenteredActivityIndicator:(BOOL)hasCenteredActivityIndicator
{
    objc_setAssociatedObject(self,
                             @selector(hasCenteredActivityIndicator),
                             @(hasCenteredActivityIndicator),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (BOOL)isLoading
{
    return [objc_getAssociatedObject(self, @selector(isLoading)) boolValue];
}


- (void)setIsLoading:(BOOL)isLoading
{
    objc_setAssociatedObject(self,
                             @selector(isLoading),
                             @(isLoading),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    if (isLoading == YES && self.activityIndicator == nil)
    {
        // Only show image when there's a tableView which is empty.
        if ([self respondsToSelector:NSSelectorFromString(@"tableView")] &&
            [self respondsToSelector:NSSelectorFromString(@"tableView:numberOfRowsInSection:")] &&
            ([(id)self tableView:[(id)self tableView] numberOfRowsInSection:0] == 0))
        {
            self.imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TableLoading"]];
            self.imageView.alpha = 0.13f;  // Desaturated logo needs this to get (almost) equal shade as table headers.
            [self.view addSubview:self.imageView];
        }

        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        self.activityIndicator.color = [UIColor blackColor];

        [self.activityIndicator startAnimating];
        [self.view addSubview:self.activityIndicator];
    }
    else if (self.isLoading == NO && self.activityIndicator != nil)
    {
        [self.activityIndicator stopAnimating];
        [self.activityIndicator removeFromSuperview];
        self.activityIndicator = nil;

        [self.imageView removeFromSuperview];
        self.imageView = nil;
    }

    [self didSetIsLoading];
}


- (void)didSetIsLoading
{
    // Dummy implementation; override by subclass.
}


#pragma mark - View Related

- (void)viewWillLayoutSubviewsSwizzled
{
    [self viewWillLayoutSubviewsSwizzled];

    if (self.activityIndicator != nil && self.hasCenteredActivityIndicator == NO)
    {
        UIView* topView = [[[[UIApplication sharedApplication] keyWindow] subviews] lastObject];
        CGPoint center = topView.center;
        center = [topView convertPoint:center toView:self.view];

        self.imageView.center = center;

        // For some reason iOS' spinner is on pixels off in both X and Y.
        center.x += 1.0f;
        center.y += 1.0f;
        self.activityIndicator.center = center;

        self.hasCenteredActivityIndicator = YES;
    }
}

@end
