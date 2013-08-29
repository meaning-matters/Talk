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
#import "Strings.h"


typedef enum
{
    TableSectionForwarding   = 1UL << 0,
    TableSectionArea         = 1UL << 1,    // The optional state will be placed in a row here.
    TableSectionSubscription = 1UL << 2,
    TableSectionRealName     = 1UL << 3,
    TableSectionAddress      = 1UL << 4,
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
        sections |= TableSectionForwarding;
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
    self.flagImageView.image = [UIImage imageNamed:number.numberCountry];
    self.countryLabel.text = [[CountryNames sharedNames] nameForIsoCountryCode:number.numberCountry];
}


#pragma mark - Table View Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return [Common bitsSetCount:sections];
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString*   title = nil;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionForwarding:
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
            title = [Strings nameString];
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

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionForwarding:
            title = NSLocalizedStringWithDefaultValue(@"Number:Forwarding SectionFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"With 'Default' all devices associated with this number "
                                                      @"will ring when an incoming call is received.",
                                                      @"Explanation how to cancel a payed subscription for "
                                                      @"using a phone number\n"
                                                      @"[* lines]");
            break;

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

#warning Make fully dynamic.
    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionForwarding:
            numberOfRows = 1;
            break;

        case TableSectionArea:
            numberOfRows = 3;
            break;

        case TableSectionSubscription:
            numberOfRows = 3;
            break;

        case TableSectionRealName:
            numberOfRows = 4;
            break;

        case TableSectionAddress:
            numberOfRows = 4;
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

    switch ([Common nthBitSet:indexPath.section inValue:sections])
    {
        case TableSectionForwarding:
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

    switch ([Common nthBitSet:indexPath.section inValue:sections])
    {
        case TableSectionForwarding:
            cell = [self forwardingCellForRowAtIndexPath:indexPath];
            break;

        case TableSectionArea:
            cell = [self areaCellForRowAtIndexPath:indexPath];
            break;

        case TableSectionSubscription:
            cell = [self subscriptionCellForRowAtIndexPath:indexPath];
            break;

        case TableSectionRealName:
            cell = [self nameCellForRowAtIndexPath:indexPath];
            break;

        case TableSectionAddress:
            cell = [self addressCellForRowAtIndexPath:indexPath];
            break;
    }

    return cell;
}


- (UITableViewCell*)forwardingCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"Value2Cell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"Value2Cell"];
    }

    cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Number:Name Label", nil,
                                                            [NSBundle mainBundle], @"Forwarding",
                                                            @"....");
    cell.detailTextLabel.text = @"Default";

    cell.selectionStyle  = UITableViewCellSelectionStyleBlue;
    cell.accessoryType   = UITableViewCellAccessoryDisclosureIndicator;
    cell.imageView.image = nil;

    return cell;
}


- (UITableViewCell*)areaCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"Value2Cell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"Value2Cell"];
    }

#warning Parameterize fully: no area code available, number type, ...
    switch (indexPath.row)
    {
        case 0:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Number:NumberType Label", nil,
                                                                    [NSBundle mainBundle], @"Type",
                                                                    @"....");
            cell.detailTextLabel.text = @"Geographic";
            break;

        case 1:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Number:AreaCode Label", nil,
                                                                    [NSBundle mainBundle], @"Code",
                                                                    @"....");
            cell.detailTextLabel.text = number.areaCode;
            break;

        case 2:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Number:AreaName Label", nil,
                                                                    [NSBundle mainBundle], @"City",
                                                                    @"....");
            cell.detailTextLabel.text = @"Leuven";
            break;

#warning Add State here.
    }

    cell.selectionStyle  = UITableViewCellSelectionStyleNone;
    cell.accessoryType   = UITableViewCellAccessoryNone;
    cell.imageView.image = nil;
    
    return cell;
}


- (UITableViewCell*)subscriptionCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;
    NSDateFormatter*    dateFormatter = [[NSDateFormatter alloc] init];
    NSString*           dateFormat = [NSDateFormatter dateFormatFromTemplate:@"E MMM d yyyy"
                                                                     options:0
                                                                      locale:[NSLocale currentLocale]];
    [dateFormatter setDateFormat:dateFormat];
    [dateFormatter setLocale:[NSLocale currentLocale]];
    
    cell = [self.tableView dequeueReusableCellWithIdentifier:@"Value2Cell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"Value2Cell"];
    }

    switch (indexPath.row)
    {
        case 0:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Number:SubscriptionPurchaseDate Label", nil,
                                                                    [NSBundle mainBundle], @"Purchased",
                                                                    @"....");
            cell.detailTextLabel.text = [dateFormatter stringFromDate:number.purchaseDate];
            break;

        case 1:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Number:SubscriptionRenewalDate Label", nil,
                                                                    [NSBundle mainBundle], @"Renewal",
                                                                    @"....");
            cell.detailTextLabel.text = [dateFormatter stringFromDate:number.purchaseDate];
            break;

        case 2:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Number:SubscriptionRenewalPrice Label", nil,
                                                                    [NSBundle mainBundle], @"Price",
                                                                    @"....");
            cell.detailTextLabel.text = @"€3.79";
            break;
    }

    cell.selectionStyle  = UITableViewCellSelectionStyleNone;
    cell.accessoryType   = UITableViewCellAccessoryNone;
    cell.imageView.image = nil;
    
    return cell;
}


- (UITableViewCell*)nameCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"Value2Cell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"Value2Cell"];
    }

    switch (indexPath.row)
    {
        case 0:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Number:NameSalutation Label", nil,
                                                                    [NSBundle mainBundle], @"Title",
                                                                    @"....");
            cell.detailTextLabel.text = number.salutation;
            break;

        case 1:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Number:NameFirst Label", nil,
                                                                    [NSBundle mainBundle], @"First",
                                                                    @"....");
            cell.detailTextLabel.text = number.firstName;
            break;

        case 2:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Number:NameLast Label", nil,
                                                                    [NSBundle mainBundle], @"Last",
                                                                    @"....");
            cell.detailTextLabel.text = number.lastName;
            break;

        case 3:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Number:NameCompany Label", nil,
                                                                    [NSBundle mainBundle], @"Company",
                                                                    @"....");
            cell.detailTextLabel.text = number.company;
            break;
    }

    cell.selectionStyle  = UITableViewCellSelectionStyleNone;
    cell.accessoryType   = UITableViewCellAccessoryNone;
    cell.imageView.image = nil;
    
    return cell;
}


- (UITableViewCell*)addressCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"Value2Cell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"Value2Cell"];
    }

    switch (indexPath.row)
    {
        case 0:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Number:AddressStreet Label", nil,
                                                                    [NSBundle mainBundle], @"Street",
                                                                    @"....");
            cell.detailTextLabel.text = number.street;
            break;

        case 1:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Number:AddressBuilding Label", nil,
                                                                    [NSBundle mainBundle], @"Number",
                                                                    @"....");
            cell.detailTextLabel.text = number.building;
            break;

        case 2:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Number:AddressCity Label", nil,
                                                                    [NSBundle mainBundle], @"City",
                                                                    @"....");
            cell.detailTextLabel.text = number.city;
            break;

        case 3:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Number:AddressZip Label", nil,
                                                                    [NSBundle mainBundle], @"ZIP Code",
                                                                    @"....");
            cell.detailTextLabel.text = number.zipCode;
            break;
    }

    cell.selectionStyle  = UITableViewCellSelectionStyleNone;
    cell.accessoryType   = UITableViewCellAccessoryNone;
    cell.imageView.image = nil;
    
    return cell;
}

@end
