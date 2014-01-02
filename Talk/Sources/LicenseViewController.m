//
//  LicenseViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 26/05/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "LicenseViewController.h"


@interface LicenseViewController ()
{
    NSString*   licenseText;
}

@end


@implementation LicenseViewController

- (instancetype)initWithDictionary:(NSDictionary*)dictionary
{
    if (self = [super initWithNibName:@"LicenseView" bundle:nil])
    {
        self.title  = [dictionary allKeys][0];

        licenseText = [dictionary allValues][0];
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    NSString* htmlTop    = @"<!DOCTYPE HTML><html><head><style>body{font-family:'Helvetica';font-size:14px</style><body>";
    NSString* htmlBottom = @"</body></html>";

    licenseText = [NSString stringWithFormat:@"%@%@%@", htmlTop, licenseText, htmlBottom];

    self.webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;

    [self.webView loadHTMLString:licenseText baseURL:nil];
}

@end