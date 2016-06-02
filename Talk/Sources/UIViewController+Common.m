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
#import "Settings.h"
#import "NSTimer+Blocks.h"


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
    objc_setAssociatedObject(self, @selector(activityIndicator), activityIndicator, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (UIImageView*)imageView
{
    return objc_getAssociatedObject(self, @selector(imageView));
}


- (void)setImageView:(UIImageView*)imageView
{
    objc_setAssociatedObject(self, @selector(imageView), imageView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (BOOL)hasCenteredActivityIndicator
{
    return [objc_getAssociatedObject(self, @selector(hasCenteredActivityIndicator)) boolValue];
}


- (void)setHasCenteredActivityIndicator:(BOOL)hasCenteredActivityIndicator
{
    objc_setAssociatedObject(self, @selector(hasCenteredActivityIndicator), @(hasCenteredActivityIndicator), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (BOOL)isLoading
{
    return [objc_getAssociatedObject(self, @selector(isLoading)) boolValue];
}


- (void)setIsLoading:(BOOL)isLoading
{
    objc_setAssociatedObject(self, @selector(isLoading), @(isLoading), OBJC_ASSOCIATION_RETAIN_NONATOMIC);

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


- (BOOL)showFootnotes
{
    return [objc_getAssociatedObject(self, @selector(showFootnotes)) boolValue];
}


- (void)setShowFootnotes:(BOOL)showFootnotes
{
    objc_setAssociatedObject(self, @selector(showFootnotes), @(showFootnotes), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (BOOL)settingsShowFootnotes
{
    return [objc_getAssociatedObject(self, @selector(settingsShowFootnotes)) boolValue];
}


- (void)setSettingsShowFootnotes:(BOOL)settingsShowFootnotes
{
    objc_setAssociatedObject(self, @selector(settingsShowFootnotes), @(settingsShowFootnotes), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (UITableView*)localTableView
{
    return objc_getAssociatedObject(self, @selector(localTableView));
}


- (void)setLocalTableView:(UITableView*)localTableView
{
    objc_setAssociatedObject(self, @selector(localTableView), localTableView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (id<NSObject>)defaultsObserver
{
    return objc_getAssociatedObject(self, @selector(defaultsObserver));
}


- (void)setDefaultsObserver:(id<NSObject>)defaultsObserver
{
    objc_setAssociatedObject(self, @selector(defaultsObserver), defaultsObserver, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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


- (void)updateAllSectionsOfTableView:(UITableView*)tableView
{
    NSRange     range    = NSMakeRange(0, [tableView numberOfSections]);
    NSIndexSet* indexSet = [NSIndexSet indexSetWithIndexesInRange:range];

    [tableView beginUpdates];
    [tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
    [tableView endUpdates];
}


#pragma mark - Footnotes Stuff

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldReceiveTouch:(UITouch*)touch
{
    NSIndexPath* indexPath = [self.localTableView indexPathForRowAtPoint:[touch locationInView:self.localTableView]];

    if (indexPath != nil)
    {
        // When tapping on a section header we do get an indexPath strange enough (except for section 0, even more
        // stange).  When user taps on section header we do however want to show footnotes, so we filter this case.
        // Turns out the the touched view is the header's contentView, so that's what we check.
        UIView* headerContentView = [self.localTableView headerViewForSection:indexPath.section].contentView;
        if (headerContentView != nil && headerContentView == touch.view)
        {
            return YES;
        }
        else
        {
            return NO;
        }
    }
    else
    {
        return YES;
    }
}


- (void)longPressAction:(UILongPressGestureRecognizer*)sender
{
    if ([Settings sharedSettings].showFootnotes == NO)
    {
        if (sender.state == UIGestureRecognizerStateBegan)
        {
            self.showFootnotes = YES;

            [self updateAllSectionsOfTableView:self.localTableView];
        }

        if (sender.state == UIGestureRecognizerStateEnded)
        {
            __weak typeof(self) weakSelf = self;
            [NSTimer scheduledTimerWithTimeInterval:3 repeats:NO block:^
            {
                weakSelf.showFootnotes = [Settings sharedSettings].showFootnotes;

                [weakSelf updateAllSectionsOfTableView:weakSelf.localTableView];
            }];
        }
    }
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self.defaultsObserver];
    self.defaultsObserver = nil;
}


- (void)setupFootnotesHandlingOnTableView:(UITableView*)tableView
{
    self.localTableView        = tableView;
    self.showFootnotes         = [Settings sharedSettings].showFootnotes;
    self.settingsShowFootnotes = [Settings sharedSettings].showFootnotes;

    UILongPressGestureRecognizer* recognizer;
    recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                               action:@selector(longPressAction:)];
    [self.localTableView addGestureRecognizer:recognizer];
    recognizer.delegate = self;

    __weak typeof(self) weakSelf = self;
    self.defaultsObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification
                                                                              object:nil
                                                                               queue:[NSOperationQueue mainQueue]
                                                                          usingBlock:^(NSNotification* note)
    {
        if ([Settings sharedSettings].showFootnotes != weakSelf.settingsShowFootnotes)
        {
            weakSelf.showFootnotes         = [Settings sharedSettings].showFootnotes;   // Reset local preference.
            weakSelf.settingsShowFootnotes = [Settings sharedSettings].showFootnotes;

            [weakSelf updateAllSectionsOfTableView:weakSelf.localTableView];
        }
    }];
}

@end
