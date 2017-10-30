//
//  NewConversationViewController.m
//  Talk
//
//  Created by Jeroen Kooiker on 30/10/2017.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import "NewConversationViewController.h"

@interface NewConversationViewController ()

@end

@implementation NewConversationViewController


- (instancetype)init
{
    if (self = [super initWithNibName:@"NewConversationView" bundle:nil])
    {
        self.title = @"New Message"; // @TODO: Change to NSLocalizedString.
        // The tabBarItem image must be set in my own NavigationController.
    }
    
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController setToolbarHidden:NO];
    
    UIBarButtonItem* cancelButton;
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                 target:self
                                                                 action:@selector(cancelAction)];
    self.navigationItem.rightBarButtonItem = cancelButton;
}


- (void)cancelAction
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
