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


typedef enum
{
    TableSectionTexts   = 1UL << 0,
    TableSectionMessage = 1UL << 1,
    TableSectionCall    = 1UL << 2,
} TableSections;


@interface HelpsViewController ()
{
    NSArray*      helpsArray;
    TableSections sections;
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

        sections |= TableSectionTexts;
        sections |= TableSectionMessage;
        sections |= TableSectionCall;
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

    BOOL pushed = [self isMovingToParentViewController];
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:!pushed];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return [Common bitsSetCount:sections];
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionTexts:
            numberOfRows = helpsArray.count;
            break;

        case TableSectionMessage:
            numberOfRows = 1;
            break;

        case TableSectionCall:
            numberOfRows = 1;
            break;
    }
    
    return numberOfRows;
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];

    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }

    cell.textLabel.text = [helpsArray[indexPath.row] allKeys][0];
    cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    HelpViewController* helpViewController;

    helpViewController = [[HelpViewController alloc] initWithDictionary:helpsArray[indexPath.row]];
    [self.navigationController pushViewController:helpViewController animated:YES];
}

@end
