//
//  LicensesViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 26/05/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "LicensesViewController.h"
#import "HtmlViewController.h"
#import "Common.h"


@interface LicensesViewController ()
{
    NSMutableArray* licensesArray;
}

@end


@implementation LicensesViewController

- (instancetype)init
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


#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return licensesArray.count;
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }

    cell.textLabel.text = [licensesArray[indexPath.row] allKeys][0];
    cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString*   title = nil;

    title = NSLocalizedStringWithDefaultValue(@"Licenses SectionFooter", nil,
                                              [NSBundle mainBundle],
                                              @"The licences of open-source software used in this app.",
                                              @"[* lines]");

    return title;
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    HtmlViewController* viewController;

    viewController = [[HtmlViewController alloc] initWithDictionary:licensesArray[indexPath.row] modal:NO];
    [self.navigationController pushViewController:viewController animated:YES];
}


#pragma mark - Helpers

- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
