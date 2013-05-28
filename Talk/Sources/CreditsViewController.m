//
//  CreditsViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 27/05/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "CreditsViewController.h"
#import "Common.h"


@implementation CreditsViewController

- (id)init
{
    if (self = [super initWithNibName:@"CreditsView" bundle:nil])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"Credits ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"Credits",
                                                       @"Title of app screen with credits/thanks (no calling credit)\n"
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

    NSString*       path = [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"Credits.rtf"];
    NSURL*          url = [[NSURL alloc] initFileURLWithPath:path];
    NSURLRequest*   request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}


#pragma mark - Helpers

- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
