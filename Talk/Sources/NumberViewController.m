//
//  NumberViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 27/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "NumberViewController.h"
#import "Common.h"
#import "PhoneNumber.h"
#import "CountryNames.h"


typedef enum
{
    TableSectionNumber       = 1UL << 0,
    TableSectionForwarding   = 1UL << 1,
    TableSectionCountry      = 1UL << 2, // The optional state will be placed in a row under country.
    TableSectionArea         = 1UL << 3,
    TableSectionSubscription = 1UL << 4,
    TableSectionRealName     = 1UL << 5,
    TableSectionAddress      = 1UL << 6,
} TableSections;


@interface NumberViewController ()
{
    NumberData*     number;
    TableSections   sections;
}

@end


@implementation NumberViewController

- (id)initWithNumber:(NumberData*)theNumber
{
    if (self = [super initWithNibName:@"NumberView" bundle:nil])
    {
        number = theNumber;

        self.title = NSLocalizedStringWithDefaultValue(@"Number:NumberDetails ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"Number",
                                                       @"Title of app screen with details of a phone number\n"
                                                       @"[1 line larger font].");

        // Mandatory sections.
        sections |= TableSectionNumber;
        sections |= TableSectionForwarding;
        sections |= TableSectionCountry;
        sections |= TableSectionArea;
        sections |= TableSectionSubscription;

        // Optional sections.
        sections |= (number.firstName != nil) ? TableSectionRealName : 0;
        sections |= (number.street    != nil) ? TableSectionAddress  : 0;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = self.editButtonItem;

    [[NSBundle mainBundle] loadNibNamed:@"NumberHeaderView" owner:self options:nil];
    self.tableView.tableHeaderView = self.tableHeaderView;
    self.tableView.allowsSelectionDuringEditing = YES;

    self.nameTextField.text = number.name;
    self.numberLabel.text = [[PhoneNumber alloc] initWithNumber:number.e164].internationalFormat;
    self.flagImageView.image = [UIImage imageNamed:number.isoCountryCode];
    self.countryLabel.text = [[CountryNames sharedNames] nameForIsoCountryCode:number.isoCountryCode];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - Table View Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return [Common countSetBits:sections];
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString*   title = nil;

    switch ([Common getNthSetBit:section inValue:sections])
    {
        case TableSectionNumber:
            break;

        case TableSectionForwarding:
            break;

        case TableSectionCountry:
            title = NSLocalizedStringWithDefaultValue(@"Number:Country SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Country",
                                                      @"....");
            break;

        case TableSectionArea:
            title = NSLocalizedStringWithDefaultValue(@"Number:Area SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Area",
                                                      @"....");
            break;

        case TableSectionSubscription:
            title = NSLocalizedStringWithDefaultValue(@"Number:Subscription SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Subscription",
                                                      @"....");
            break;

        case TableSectionRealName:
            title = NSLocalizedStringWithDefaultValue(@"Number:Name SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Name",
                                                      @"....");
            break;

        case TableSectionAddress:
            title = NSLocalizedStringWithDefaultValue(@"Number:Address SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Address",
                                                      @"....");
            break;
    }

    return title;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString*   title = nil;

    switch ([Common getNthSetBit:section inValue:sections])
    {
        case TableSectionSubscription:
            title = NSLocalizedStringWithDefaultValue(@"Number:Subscription SectionFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"To cancel the subscription ...",
                                                      @"Explanation how to cancel a payed subscription for "
                                                      @"using a phone number\n"
                                                      @"[* lines]");
            break;
    }

    return title;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger   numberOfRows = 0;

    switch ([Common getNthSetBit:section inValue:sections])
    {
        case TableSectionNumber:
            numberOfRows = 2;
            break;

        case TableSectionForwarding:
            numberOfRows = 1;
            break;

        case TableSectionCountry:
            numberOfRows = 1;
            break;

        case TableSectionArea:
            numberOfRows = 1;
            break;

        case TableSectionSubscription:
            numberOfRows = 1;
            break;

        case TableSectionRealName:
            numberOfRows = 1;
            break;

        case TableSectionAddress:
            numberOfRows = 1;
            break;
    }

    return numberOfRows;
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    if ([self.tableView cellForRowAtIndexPath:indexPath].selectionStyle == UITableViewCellSelectionStyleNone)
    {
        return;
    }

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch ([Common getNthSetBit:indexPath.section inValue:sections])
    {
        case TableSectionNumber:
            break;

        case TableSectionForwarding:
            break;

        case TableSectionCountry:
            break;

        case TableSectionArea:
            break;

        case TableSectionSubscription:
            break;

        case TableSectionRealName:
            break;
            
        case TableSectionAddress:
            break;
    }
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell = nil;

    switch ([Common getNthSetBit:indexPath.section inValue:sections])
    {
        case TableSectionNumber:
            cell = [self numberCellForRowAtIndexPath:indexPath];
            break;

        case TableSectionForwarding:
            cell = [self numberCellForRowAtIndexPath:indexPath];
            break;

        case TableSectionCountry:
            cell = [self numberCellForRowAtIndexPath:indexPath];
            break;

        case TableSectionArea:
            cell = [self numberCellForRowAtIndexPath:indexPath];
            break;

        case TableSectionSubscription:
            cell = [self numberCellForRowAtIndexPath:indexPath];
            break;

        case TableSectionRealName:
            cell = [self numberCellForRowAtIndexPath:indexPath];
            break;

        case TableSectionAddress:
            cell = [self numberCellForRowAtIndexPath:indexPath];
            break;
    }

    return cell;
}


- (UITableViewCell*)numberCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"Value2Cell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"Value2Cell"];
    }

    if (indexPath.row == 0)
    {
        cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Number:Name Label", nil,
                                                                [NSBundle mainBundle], @"Name",
                                                                @"....");
        cell.detailTextLabel.text = number.name;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    else
    {
        cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Number:Number Label", nil,
                                                                [NSBundle mainBundle], @"Number",
                                                                @"....");
        cell.detailTextLabel.text = [[PhoneNumber alloc] initWithNumber:number.e164].internationalFormat;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    cell.imageView.image = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;

    return cell;
}

@end
