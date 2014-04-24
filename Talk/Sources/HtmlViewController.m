//
//  HtmlViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 11/08/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "HtmlViewController.h"


@interface HtmlViewController ()
{
    NSString* htmlBody;
}

@end


@implementation HtmlViewController

- (instancetype)initWithDictionary:(NSDictionary*)dictionary
{
    if (self = [super initWithNibName:@"HtmlView" bundle:nil])
    {
        self.title = [dictionary allKeys][0];

        htmlBody   = [dictionary allValues][0];
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    if (self.presentingViewController != nil)
    {
        // Shown as modal.
        UIBarButtonItem*    buttonItem;
        buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                   target:self
                                                                   action:@selector(cancel)];
        self.navigationItem.leftBarButtonItem = buttonItem;
    }

    NSString* htmlTop    = @"<!DOCTYPE HTML><html><head><style>body{font-family:'Helvetica';font-size:14px</style><body>";
    NSString* htmlBottom = @"</body></html>";
    NSString* html       = [NSString stringWithFormat:@"%@%@%@", htmlTop, htmlBody, htmlBottom];

    self.webView.dataDetectorTypes           = UIDataDetectorTypeNone;
    self.webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;

    [self.webView loadHTMLString:html baseURL:nil];
}


#pragma mark - Helpers

- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
