//
//  NumberAreaTitlesViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 18/08/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "NumberAreaTitlesViewController.h"
#import "Strings.h"


@interface NumberAreaTitlesViewController ()

@property (nonatomic, strong) AddressData* address;
@property (nonatomic, strong) NSIndexPath* selectedIndexPath;

@end


@implementation NumberAreaTitlesViewController

- (instancetype)initWithAddress:(AddressData*)address
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"NumbersAreaTitles ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"Titles",
                                                       @"Title of screen with list of titles: Mr., Ms., ...\n"
                                                       @"[1 line larger font].");

        self.address = address;
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
        {
            selected               = [self.address.salutation isEqualToString:@"MR"];
            self.selectedIndexPath = selected ? indexPath : self.selectedIndexPath;
            cell.accessoryType     = selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            cell.textLabel.text    = [Strings mrString];
            break;
        }
        case 1:
        {
            selected               = [self.address.salutation isEqualToString:@"MS"];
            self.selectedIndexPath = selected ? indexPath : self.selectedIndexPath;
            cell.accessoryType     = selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            cell.textLabel.text    = [Strings msString];
            break;
        }
        case 2:
        {
            selected               = [self.address.salutation isEqualToString:@"COMPANY"];
            self.selectedIndexPath = selected ? indexPath : self.selectedIndexPath;
            cell.accessoryType     = selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            cell.textLabel.text    = [Strings companyString];
            break;
        }
    }

    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    switch (indexPath.row)
    {
        case 0:
        {
            self.address.salutation = @"MR";
            break;
        }
        case 1:
        {
            self.address.salutation = @"MS";
            break;
        }
        case 2:
        {
            self.address.salutation = @"COMPANY";
            break;
        }
    }

    UITableViewCell* cell;

    cell               = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;

    cell               = [tableView cellForRowAtIndexPath:self.selectedIndexPath];
    cell.accessoryType = UITableViewCellAccessoryNone;

    [self.navigationController popViewControllerAnimated:YES];
}

@end
