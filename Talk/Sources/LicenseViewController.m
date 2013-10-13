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

    self.textView.text = licenseText;
}

@end
