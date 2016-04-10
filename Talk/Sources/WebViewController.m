//
//  WebViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 10/04/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import "WebViewController.h"


@interface WebViewController ()

@property (nonatomic, weak) IBOutlet UIWebView* webView;
@property (nonatomic, strong) NSString*         urlString;

@end


@implementation WebViewController

- (instancetype)initWithUrlString:(NSString*)urlString
{
    if (self = [super initWithNibName:@"WebView" bundle:nil])
    {
        self.title     = NSLocalizedString(@"Web URL", @"");

        self.urlString = urlString;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem* buttonItem;
    buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                               target:self
                                                               action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = buttonItem;

    NSURL*        url     = [NSURL URLWithString:self.urlString];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];

    [self.webView loadRequest:request];
}


#pragma mark - Helpers

- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
