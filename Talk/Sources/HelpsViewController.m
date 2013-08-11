//
//  HelpsViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "HelpsViewController.h"
#import "HelpViewController.h"
#import "Common.h"


@interface HelpsViewController ()
{
    NSArray* helpsArray;
}

@end


@implementation HelpsViewController

- (id)init
{
    if (self = [super initWithNibName:@"HelpsView" bundle:nil])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"Helps ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"Help",
                                                       @"Title of app screen with list of help items\n"
                                                       @"[1 line larger font].");
        self.tabBarItem.image = [UIImage imageNamed:@"HelpsTab.png"];

        NSData* data = [Common dataForResource:@"Helps" ofType:@"json"];
        helpsArray   = [Common objectWithJsonData:data];
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return helpsArray.count;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];

    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }

    cell.textLabel.text = [helpsArray[indexPath.section] allKeys][0];
    cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    HelpViewController* helpViewController;

    helpViewController = [[HelpViewController alloc] initWithDictionary:helpsArray[indexPath.section]];
    [self.navigationController pushViewController:helpViewController animated:YES];
}

@end
