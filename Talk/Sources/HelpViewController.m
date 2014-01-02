//
//  HelpViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 11/08/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "HelpViewController.h"


@interface HelpViewController ()
{
    NSString*   helpText;
}

@end


@implementation HelpViewController

- (instancetype)initWithDictionary:(NSDictionary*)dictionary
{
    if (self = [super initWithNibName:@"HelpView" bundle:nil])
    {
        self.title = [dictionary allKeys][0];

        helpText   = [dictionary allValues][0];
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    NSString* htmlTop    = @"<!DOCTYPE HTML><html><head><style>body{font-family:'Helvetica';font-size:14px</style><body>";
    NSString* htmlBottom = @"</body></html>";

    helpText = [NSString stringWithFormat:@"%@%@%@", htmlTop, helpText, htmlBottom];

    self.webView.dataDetectorTypes           = UIDataDetectorTypeNone;
    self.webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;

    [self.webView loadHTMLString:helpText baseURL:nil];
}

@end
