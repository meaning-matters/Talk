//
//  LicensesViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 26/05/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "LicensesViewController.h"
#import "LicenseViewController.h"
#import "Common.h"


@interface LicensesViewController ()
{
    NSMutableArray* licensesArray;
}

@end


@implementation LicensesViewController

- (id)init
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"Licenses ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"Licenses",
                                                       @"Title of app screen with licenses info\n"
                                                       @"[1 line larger font].");

        NSData*  data  = [Common dataForResource:@"Licenses" ofType:@"json"];
        NSArray* array = [Common objectWithJsonData:data];

        licensesArray = [NSMutableArray array];
        for (NSDictionary* license in array)
        {
            if ([[license allKeys][0] hasPrefix:@"__"] == NO)
            {
                [licensesArray addObject:license];
            }
        }
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
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return licensesArray.count;
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

    cell.textLabel.text = [licensesArray[indexPath.section] allKeys][0];
    cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString*   title = nil;

    if (section == licensesArray.count - 1)
    {
        title = NSLocalizedStringWithDefaultValue(@"Licenses SectionFooter", nil,
                                                  [NSBundle mainBundle],
                                                  @"The licences of open source software used in this app.",
                                                  @"[* lines]");
    }

    return title;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    LicenseViewController* licenceViewController;

    licenceViewController = [[LicenseViewController alloc] initWithDictionary:licensesArray[indexPath.section]];
    [self.navigationController pushViewController:licenceViewController animated:YES];
}


#pragma mark - Helpers

- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
