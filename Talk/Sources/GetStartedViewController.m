//
//  GetStartedViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 16/03/14.
//  Copyright (c) 2014 NumberBay Ltd. All rights reserved.
//

#import "GetStartedViewController.h"
#import "AnalyticsTransmitter.h"
#import "Common.h"
#import "Settings.h"
#import "BlockAlertView.h"
#import "Strings.h"
#import "DataManager.h"
#import "GetStartedStartViewController.h"
#import "GetStartedRestoreViewController.h"
#import "NSTimer+Blocks.h"
#import "WebClient.h"
#import "NetworkStatus.h"
#import "NSTimer+Blocks.h"


@interface GetStartedViewController ()

@property (nonatomic, strong) NSArray*        texts;
@property (nonatomic, assign) NSUInteger      numberOfPages;
@property (nonatomic, strong) NSMutableArray* imageViews;
@property (nonatomic, assign) NSInteger       changingPage; // Is -1 if no page change busy.
@property (nonatomic, strong) NSTimer*        slideShowTimer;
@property (nonatomic, assign) BOOL            jumpingBack;
@property (nonatomic, assign) BOOL            showAsIntro;
@property (nonatomic, assign) id              internetObserver;
@property (nonatomic, assign) BOOL            freeAccount;
@property (nonatomic, strong) NSTimer*        freeAccountTimer;

@end


@implementation GetStartedViewController

- (id)initShowAsIntro:(BOOL)showAsIntro
{
    AnalysticsTrace(@"initShowAsIntro");

    if (self = [super initWithNibName:@"GetStartedView" bundle:nil])
    {
        self.showAsIntro = showAsIntro;

        if (showAsIntro == YES)
        {
            self.title = NSLocalizedStringWithDefaultValue(@"GetStarted IntroScreenTitle", nil,
                                                           [NSBundle mainBundle], @"Intro",
                                                           @"Title of app screen ...\n"
                                                           @"[1 line larger font].");
        }
        else
        {
            self.title = NSLocalizedStringWithDefaultValue(@"GetStarted NormalScreenTitle", nil,
                                                           [NSBundle mainBundle], @"Get Started",
                                                           @"Title of app screen ...\n"
                                                           @"[1 line larger font].");
        }

        NSData* data       = [Common dataForResource:@"GetStarted" ofType:@"json"];
        self.texts         = [Common objectWithJsonData:data];
        self.numberOfPages = self.texts.count;
    }

    return self;
}


- (void)viewDidLoad
{
    AnalysticsTrace(@"viewDidLoad");

    [super viewDidLoad];

    if (self.showAsIntro == NO)
    {
        [self.restoreButton setTitle:NSLocalizedStringWithDefaultValue(@"GetStarted RestoreButtonTitle", nil,
                                                                       [NSBundle mainBundle], @"Log In",
                                                                       @"...")
                            forState:UIControlStateNormal];
        [self.startButton setTitle:NSLocalizedStringWithDefaultValue(@"GetStarted StartButtonTitle", nil,
                                                                     [NSBundle mainBundle], @"Sign Up",
                                                                     @"...")
                          forState:UIControlStateNormal];
    }

    // Set the correct alpha for all images.
    [self scrollViewDidScroll:self.scrollView];

    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.scrollsToTop = NO;
    self.scrollView.delegate = self;

    self.pageControl.numberOfPages = self.numberOfPages;
    self.pageControl.currentPage = 0;
    self.changingPage = -1;

    if (self.showAsIntro == YES)
    {
        self.startButton.alpha   = 0.0;
        self.restoreButton.alpha = 0.0;

        self.startButton.userInteractionEnabled   = NO;
        self.restoreButton.userInteractionEnabled = NO;
    }
    else
    {
        [Common styleButton:self.startButton   withColor:[UIColor whiteColor] highlightTextColor:[UIColor blackColor]];
        [Common styleButton:self.restoreButton withColor:[UIColor whiteColor] highlightTextColor:[UIColor blackColor]];
    }

    self.imageViews = [[NSMutableArray alloc] initWithCapacity:self.numberOfPages];
    for (int page = 0; page < self.numberOfPages; page++)
    {
        UIImageView* imageView     = [[UIImageView alloc] initWithFrame:self.view.bounds];
        imageView.contentMode      = UIViewContentModeScaleAspectFill;
        imageView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
        imageView.image            = [UIImage imageNamed:[NSString stringWithFormat:@"GetStarted%d.png", page + 1]];
        [self.imageViews addObject:imageView];
        [self.view insertSubview:imageView atIndex:0];
    }

    for (int page = 0; page < self.numberOfPages; page++)
    {
        [self loadScrollViewForPage:page];
    }

    if (self.showAsIntro)
    {
        [Common setY:(self.pageControl.frame.origin.y + 20.0f) ofView:self.pageControl];
    }

    self.internetLabel.text = NSLocalizedString(@"Please connect to Internet.", @"");
}


- (void)viewWillAppear:(BOOL)animated
{
    AnalysticsTrace(@"viewWillAppear");
    
    [super viewWillAppear:animated];

    for (int page = 0; page < self.numberOfPages; page++)
    {
        CGRect rect = self.view.bounds;

        [Common setHeight:rect.size.height ofView:self.imageViews[page]];
    }

    self.slideShowTimer = [NSTimer scheduledTimerWithInterval:10.0 repeats:YES block:^(void)
    {
        NSInteger nextPage = (self.pageControl.currentPage + 1) % self.numberOfPages;
        self.jumpingBack   = (nextPage == 0);
        [self gotoPage:nextPage];
    }];

    [self getFreeAccount];
}


- (void)viewWillDisappear:(BOOL)animated
{
    AnalysticsTrace(@"viewWillDisappear");

    [super viewWillDisappear:animated];
    [self stopSlideShow];
}


- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    CGSize size = CGSizeMake(self.scrollView.frame.size.width * self.numberOfPages,
                             self.scrollView.frame.size.height - self.restoreButton.frame.size.height - 20.0f);
    self.scrollView.contentSize = size;
}


- (void)setFreeAccount:(BOOL)freeAccount
{
    _freeAccount = freeAccount;

    if (freeAccount == NO && self.showAsIntro == NO)
    {
        UIBarButtonItem* rightBarButtonItem;
        rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                           target:self
                                                                           action:@selector(cancel)];
        self.navigationItem.rightBarButtonItem = rightBarButtonItem;
    }
    else
    {
        self.navigationItem.rightBarButtonItem = nil;
    }
}


- (void)getFreeAccount
{
    NSTimeInterval duration = 1.0;

    self.startButton.enabled   = NO;
    self.restoreButton.enabled = NO;
    self.startButton.alpha     = 0.5;
    self.restoreButton.alpha   = 0.5;

    self.internetLabel.alpha   = 0.0;

    void (^retrieveOptions)() = ^void()
    {
        [[WebClient sharedClient] retrieveOptions:^(NSError* error, BOOL freeAccount)
        {
            if (error.code == WebStatusFailSecureInternet ||
                error.code == WebStatusFailNoInternet     ||
                error.code == WebStatusFailInternetLogin  ||
                error.code == WebStatusFailRoamingOff)
            {
                // Ignore because there's no internet connection yet.
            }
            else
            {
                // We get here when all went well, or when there's an error.
                if (error != nil)
                {
                    NBLog(@"Error getting /options: %@", error);
                }

                // We'll have to reset the state even if there's an error, because we're not handling errors.
                self.freeAccount = freeAccount;

                self.startButton.enabled   = YES;
                self.restoreButton.enabled = YES;
                self.startButton.alpha     = 1.0;
                self.restoreButton.alpha   = 1.0;
                self.internetLabel.alpha   = 0.0;

                [self.freeAccountTimer invalidate];
                self.freeAccountTimer = nil;

                [[NSNotificationCenter defaultCenter] removeObserver:self.internetObserver];
                self.internetObserver = nil;
            }
        }];
    };

    NetworkStatusReachable reachable = [NetworkStatus sharedStatus].reachableStatus;
    if (reachable == NetworkStatusReachableWifi || reachable == NetworkStatusReachableCellular)
    {
        retrieveOptions();
    }
    else if (self.internetObserver == nil)
    {
        self.freeAccountTimer = [NSTimer scheduledTimerWithInterval:duration repeats:YES block:^
        {
            [UIView animateWithDuration:duration animations:^
            {
                self.internetLabel.alpha = self.internetLabel.alpha == 1 ? 0 : 1;

                // Poll to catch switch between Wi-Fi behind-captive-portal and being-logged-in.
                NetworkStatusReachable reachable = [NetworkStatus sharedStatus].reachableStatus;
                if (reachable == NetworkStatusReachableWifi || reachable == NetworkStatusReachableCellular ||
                    self.internetLabel.alpha == 1)
                {
                    retrieveOptions();
                }
            }];
        }];

        self.internetObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NetworkStatusReachableNotification
                                                                                  object:nil
                                                                                   queue:[NSOperationQueue mainQueue]
                                                                              usingBlock:^(NSNotification* notification)
        {
            NetworkStatusReachable reachable = [notification.userInfo[@"status"] intValue];

            if (reachable == NetworkStatusReachableWifi || reachable == NetworkStatusReachableCellular)
            {
                retrieveOptions();
            }
        }];
    }
}


- (void)cancel
{
    AnalysticsTrace(@"cancel");

    NSString* title;
    NSString* message;

    title   = NSLocalizedStringWithDefaultValue(@"GetStarted CancelTitle", nil,
                                                [NSBundle mainBundle], @"Have A Look",
                                                @"Alert title:\n"
                                                @"[iOS alert title size]");

    message = NSLocalizedStringWithDefaultValue(@"GetStarted CancelMessage", nil,
                                                [NSBundle mainBundle],
                                                @"Before becoming a member of %@, you're welcome to have a "
                                                @"look around the app.\n\n"
                                                @"You can return here by trying to call, do a few other things, "
                                                @"or by tapping Get Started on the Settings tab.",
                                                @"Alert message: ...\n"
                                                @"[iOS alert message size]");
    message = [NSString stringWithFormat:message, [Settings sharedSettings].appDisplayName];

    [BlockAlertView showAlertViewWithTitle:title
                                   message:message
                                completion:^(BOOL cancelled, NSInteger buttonIndex)
    {
        if (cancelled == NO)
        {
            AnalysticsTrace(@"Look");

            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
                         cancelButtonTitle:[Strings cancelString]
                         otherButtonTitles:[Strings lookString], nil];
}


- (void)loadScrollViewForPage:(NSUInteger)page
{
    if (page >= self.numberOfPages)
    {
        return;
    }

    CGFloat scrollHeight = self.scrollView.frame.size.height;
    CGFloat bodyToScroll =  27.0f;  // Vertical distance between bottom of body and bottom of scroll view.
    CGFloat titleToBody  =  13.0f;  // Vertical distance between top of title and top of body.
    CGFloat titleWidth   = 280.0f;
    CGFloat titleHeight  =  21.0f;
    CGFloat bodyWidth    = 290.0f;
    CGFloat bodyHeight   =  75.0f;
    CGFloat xOffset      = 320.0f * page;

    if (self.showAsIntro)
    {
        bodyToScroll -= 20;
    }

    // Add title.
    CGRect   titleFrame                 = CGRectMake(xOffset + (320.0f - titleWidth) / 2,
                                                     scrollHeight - bodyToScroll - bodyHeight - titleToBody,
                                                     titleWidth,
                                                     titleHeight);
    UILabel* titleLabel                 = [[UILabel alloc] initWithFrame:titleFrame];
    titleLabel.text                     = self.texts[page][@"title"];
    titleLabel.textAlignment            = NSTextAlignmentCenter;
    titleLabel.font                     = [UIFont boldSystemFontOfSize:18.0f];
    titleLabel.textColor                = [UIColor whiteColor];
    titleLabel.autoresizingMask         = UIViewAutoresizingFlexibleTopMargin;
    [Common addShadowToView:titleLabel];
    [self.scrollView addSubview:titleLabel];

    // Add body.
    CGRect      bodyFrame               = CGRectMake(xOffset + (320.0f - bodyWidth) / 2,
                                                     scrollHeight - bodyToScroll - bodyHeight,
                                                     bodyWidth,
                                                     bodyHeight);
    UITextView* bodyTextView            = [[UITextView alloc] initWithFrame:bodyFrame];
    bodyTextView.text                   = self.texts[page][@"body"];
    bodyTextView.textAlignment          = NSTextAlignmentCenter;
    bodyTextView.font                   = [UIFont systemFontOfSize:17.0f];
    bodyTextView.textColor              = [UIColor whiteColor];
    bodyTextView.backgroundColor        = [UIColor clearColor];
    bodyTextView.userInteractionEnabled = NO;
    bodyTextView.autoresizingMask       = UIViewAutoresizingFlexibleTopMargin;
    [Common addShadowToView:bodyTextView];
    [self.scrollView addSubview:bodyTextView];
}


#pragma mark - Scrollview Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Calculate position: between 0 and numberOfPages - 1.
    float position = self.scrollView.contentOffset.x / CGRectGetWidth(self.scrollView.frame);

    if (self.jumpingBack == NO)
    {
        for (int n = 0; n < self.numberOfPages; n++)
        {
            UIImageView* imageView = self.imageViews[n];
            float        distance  = fabsf(n - position);

            imageView.alpha = 1.0f - distance;  // Negative values result in 0.0.
        }
    }
    else
    {
        position /= self.numberOfPages;

        ((UIView*)self.imageViews[self.numberOfPages - 1]).alpha = position;
        ((UIView*)self.imageViews[0]).alpha                      = 1.0f - position;
    }

    // Switch the page control indicator when more than 50% of the previous/next page is visible, except when changing.
    NSInteger page = floor((self.scrollView.contentOffset.x - 320 / 2) / 320) + 1;
    if (self.changingPage == -1)
    {
        self.pageControl.currentPage = page;
    }
    else
    {
        if (page == self.changingPage)
        {
            self.changingPage = -1;
        }
    }
}


- (void)scrollViewDidEndDecelerating:(UIScrollView*)scrollView
{
    self.jumpingBack = NO;
}


- (void)scrollViewWillBeginDragging:(UIScrollView*)scrollView
{
    [self stopSlideShow];
}


#pragma mark - Helpers

- (void)gotoPage:(NSInteger)page
{
	// Update the scroll view to the appropriate page.
    CGRect bounds = self.scrollView.bounds;
    bounds.origin.x = CGRectGetWidth(bounds) * page;
    bounds.origin.y = 0;
    [self.scrollView scrollRectToVisible:bounds animated:YES];
}


- (void)stopSlideShow
{
    [self.slideShowTimer invalidate];
    self.slideShowTimer = nil;
    self.jumpingBack = NO;
}


#pragma mark - Actions

- (IBAction)changePage:(id)sender
{
    AnalysticsTrace(@"changePage");

    self.changingPage = self.pageControl.currentPage;
    [self gotoPage:self.pageControl.currentPage];
    [self stopSlideShow];
}


- (IBAction)startAction:(id)sender
{
    AnalysticsTrace(@"startAction");

    GetStartedStartViewController* viewController = [[GetStartedStartViewController alloc] initWithFreeAccount:self.freeAccount];
    viewController.title = self.startButton.titleLabel.text;

    [self.navigationController pushViewController:viewController animated:YES];
}


- (IBAction)restoreAction:(id)sender
{
    AnalysticsTrace(@"restoreAction");

    GetStartedRestoreViewController* viewController = [[GetStartedRestoreViewController alloc] init];
    viewController.title = self.restoreButton.titleLabel.text;

    [self.navigationController pushViewController:viewController animated:YES];
}

@end
