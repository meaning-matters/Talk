//
//  NumberAreaTitlesViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 18/08/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "NumberAreaTitlesViewController.h"
#import "Strings.h"


@interface NumberAreaTitlesViewController ()
{
    NSMutableDictionary*    purchaseInfo;
    NSIndexPath*            selectedIndexPath;
}

@end


@implementation NumberAreaTitlesViewController

- (id)initWithPurchaseInfo:(NSMutableDictionary*)info
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"NumbersAreaTitles ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"Titles",
                                                       @"Title of screen with list of titles: Mr., Ms., ...\n"
                                                       @"[1 line larger font].");

        purchaseInfo = info;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;
    BOOL                selected;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }

    switch (indexPath.row)
    {
        case 0:
            selected            = [purchaseInfo[@"salutation"] isEqualToString:@"MS"];
            selectedIndexPath   = selected ? indexPath : selectedIndexPath;
            cell.accessoryType  = selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            cell.textLabel.text = [Strings msString];
            break;

        case 1:
            selected            = [purchaseInfo[@"salutation"] isEqualToString:@"MR"];
            selectedIndexPath   = selected ? indexPath : selectedIndexPath;
            cell.accessoryType  = selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            cell.textLabel.text = [Strings mrString];
            break;

        case 2:
            selected            = [purchaseInfo[@"salutation"] isEqualToString:@"COMPANY"];
            selectedIndexPath   = selected ? indexPath : selectedIndexPath;
            cell.accessoryType  = selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            cell.textLabel.text = [Strings companyString];
            break;
    }

    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    switch (indexPath.row)
    {
        case 0:
            purchaseInfo[@"salutation"] = @"MS";
            break;

        case 1:
            purchaseInfo[@"salutation"] = @"MR";
            break;

        case 2:
            purchaseInfo[@"salutation"] = @"COMPANY";
            break;
    }

    UITableViewCell* cell;

    cell               = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;

    cell               = [tableView cellForRowAtIndexPath:selectedIndexPath];
    cell.accessoryType = UITableViewCellAccessoryNone;

    [self.navigationController popViewControllerAnimated:YES];
}

@end
