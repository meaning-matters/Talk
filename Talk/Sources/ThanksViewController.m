//
//  ThanksViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 27/05/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "ThanksViewController.h"
#import "Common.h"


@implementation ThanksViewController

- (instancetype)init
{
    if (self = [super initWithNibName:@"ThanksView" bundle:nil])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"Thanks ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"Thanks",
                                                       @"Title of app screen with thanks\n"
                                                       @"[1 line larger font].");
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem*    buttonItem;
    buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                               target:self
                                                               action:@selector(cancel)];
    self.navigationItem.leftBarButtonItem = buttonItem;

    NSString*       path    = [[NSBundle mainBundle] pathForResource:@"Thanks" ofType:@"html"];
    NSURL*          url     = [[NSURL alloc] initFileURLWithPath:path];
    NSURLRequest*   request = [NSURLRequest requestWithURL:url];

    [self.webView loadRequest:request];
}


#pragma mark - Helpers

- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
