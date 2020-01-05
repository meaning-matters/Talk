//
//  WebViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 10/04/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import "WebViewController.h"
#import "Common.h"
#import "BlockAlertView.h"

@interface WebViewController () <UIWebViewDelegate>

@property (nonatomic, weak) IBOutlet UIWebView* webView;
@property (nonatomic, strong) NSString*         urlString;
@property (nonatomic, assign) BOOL              doneSecondLoad;

@end


@implementation WebViewController

- (instancetype)initWithUrlString:(NSString*)urlString title:(NSString*)title
{
    if (self = [super initWithNibName:@"WebView" bundle:nil])
    {
        self.title     = title;

        self.urlString = urlString;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.webView.delegate = self;
    self.isLoading = YES;
    self.webView.alpha = 0.0;

    NSURL*        url     = [NSURL URLWithString:self.urlString];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];

    [self.webView loadRequest:request];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ([self isBeingPresented])
    {
        UIBarButtonItem* buttonItem;
        buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                   target:self
                                                                   action:@selector(cancel)];
        self.navigationItem.rightBarButtonItem = buttonItem;
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


#pragma mark - Helpers

- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView*)webView
{
    if (self.doneSecondLoad == NO)
    {
        self.doneSecondLoad = YES;

        NSURL*        url     = [NSURL URLWithString:self.urlString];
        NSURLRequest* request = [NSURLRequest requestWithURL:url];

        [self.webView loadRequest:request];

    }
    else
    {
        [UIView animateWithDuration:0.5 animations:^
        {
            self.webView.alpha = 1.0;
        }];

        self.isLoading = NO;
    }
}


- (void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error
{
    self.isLoading = NO;

    [BlockAlertView showAlertViewWithTitle:@"Loading Failed"
                                   message:@"The website form to enter your message has failed to load.\n\n"
                                           @"Please make sure your iPhone is connected to Internet."
                                completion:^(BOOL cancelled, NSInteger buttonIndex)
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
                         cancelButtonTitle:@"Close"
                         otherButtonTitles:nil];
}

@end
