//
//  GetStartedViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 16/03/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import "GetStartedViewController.h"
#import "Common.h"
#import "PurchaseManager.h"
#import "Settings.h"
#import "BlockAlertView.h"
#import "Strings.h"
#import "DataManager.h"
#import "GetStartedStartViewController.h"
#import "GetStartedRestoreViewController.h"


@interface GetStartedViewController ()

@property (nonatomic, strong) NSArray*        texts;
@property (nonatomic, assign) NSUInteger      numberOfPages;
@property (nonatomic, strong) NSMutableArray* imageViews;
@property (nonatomic, assign) int             changingPage; // Is -1 if no page change busy.

@end


@implementation GetStartedViewController

- (id)init
{
    if (self = [super initWithNibName:@"GetStartedView" bundle:nil])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"GetStarted ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"Get Started",
                                                       @"Title of app screen ...\n"
                                                       @"[1 line larger font].");

        NSData* data       = [Common dataForResource:@"GetStarted" ofType:@"json"];
        self.texts         = [Common objectWithJsonData:data];
        self.numberOfPages = self.texts.count;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem* rightBarButtonItem;
    rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                       target:self
                                                                       action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = rightBarButtonItem;

    [self.restoreButton setTitle:NSLocalizedStringWithDefaultValue(@"GetStarted RestoreButtonTitle", nil,
                                                                   [NSBundle mainBundle], @"Restore",
                                                                   @"...")
                        forState:UIControlStateNormal];
    [self.startButton setTitle:NSLocalizedStringWithDefaultValue(@"GetStarted StartButtonTitle", nil,
                                                                 [NSBundle mainBundle], @"Start",
                                                                 @"...")
                      forState:UIControlStateNormal];

    self.imageViews = [[NSMutableArray alloc] initWithCapacity:self.numberOfPages];
    for (int page = 0; page < self.numberOfPages; page++)
    {
        UIImageView* imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        imageView.contentMode  = UIViewContentModeScaleAspectFill;
        imageView.image        = [UIImage imageNamed:[NSString stringWithFormat:@"GetStarted%d.png", page + 1]];
        [self.imageViews addObject:imageView];
        [self.view insertSubview:imageView atIndex:0];

        [self loadScrollViewForPage:page];
    }

    // Set the correct alpha for all images.
    [self scrollViewDidScroll:self.scrollView];

    self.scrollView.pagingEnabled = YES;
    CGSize size = CGSizeMake(self.scrollView.frame.size.width * self.numberOfPages,
                        self.scrollView.frame.size.height);
    self.scrollView.contentSize = size;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.scrollsToTop = NO;
    self.scrollView.delegate = self;

    self.pageControl.numberOfPages = self.numberOfPages;
    self.pageControl.currentPage = 0;
    self.changingPage = -1;

    [Common styleButton:self.restoreButton withColor:[UIColor whiteColor] highlightTextColor:[UIColor blackColor]];
    [Common styleButton:self.startButton   withColor:[UIColor whiteColor] highlightTextColor:[UIColor blackColor]];
}


- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
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
    [Common addShadowToView:bodyTextView];
    [self.scrollView addSubview:bodyTextView];
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    float position = self.scrollView.contentOffset.x / CGRectGetWidth(self.scrollView.frame);

    for (int n = 0; n < self.numberOfPages; n++)
    {
        UIImageView* imageView = self.imageViews[n];
        float        distance  = fabsf(n - position);

        imageView.alpha = 1.0f - distance;  // Negative values result in 0.0.
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


- (void)gotoPageAnimated:(BOOL)animated
{
    NSInteger page = self.pageControl.currentPage;

	// Update the scroll view to the appropriate page.
    CGRect bounds = self.scrollView.bounds;
    bounds.origin.x = CGRectGetWidth(bounds) * page;
    bounds.origin.y = 0;
    [self.scrollView scrollRectToVisible:bounds animated:animated];
}


#pragma mark - Actions

- (IBAction)changePage:(id)sender
{
    self.changingPage = self.pageControl.currentPage;
    [self gotoPageAnimated:YES];
}


- (IBAction)startAction:(id)sender
{
    GetStartedStartViewController* viewController = [[GetStartedStartViewController alloc] init];

    [self.navigationController pushViewController:viewController animated:YES];
}


- (IBAction)restoreAction:(id)sender
{
    GetStartedRestoreViewController* viewController = [[GetStartedRestoreViewController alloc] init];

    [self.navigationController pushViewController:viewController animated:YES];
}

@end
