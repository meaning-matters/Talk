//
//  ItemsViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 26/02/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import "ItemsViewController.h"
#import "Strings.h"
#import "Settings.h"
#import "DataManager.h"


@implementation ItemsViewController

- (id)init
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.clearsSelectionOnViewWillAppear = YES;

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                           target:self
                                                                                           action:@selector(addAction)];

    UIRefreshControl* refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:[Strings synchronizeWithServerString]];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}


- (void)refresh:(id)sender
{
    if ([Settings sharedSettings].haveAccount == YES)
    {
        [[DataManager sharedManager] synchronizeWithServer:^(NSError* error)
        {
            [sender endRefreshing];
        }];
    }
    else
    {
        [sender endRefreshing];
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    //### Workaround: http://stackoverflow.com/a/19126113/1971013
    //### And it also fixes my own issue: http://stackoverflow.com/a/22626388/1971013
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [self.refreshControl beginRefreshing];
        [self.refreshControl endRefreshing];
    });
}

@end
