//
//  NumberViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 27/03/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "NumberViewController.h"
#import "NumberDestinationsViewController.h"
#import "Common.h"
#import "PhoneNumber.h"
#import "CountryNames.h"
#import "Strings.h"
#import "BlockAlertView.h"
#import "WebClient.h"
#import "NumberLabel.h"
#import "DestinationData.h"
#import "Skinning.h"
#import "DataManager.h"
#import "Settings.h"


typedef enum
{
    TableSectionName         = 1UL << 0,
    TableSectionE164         = 1UL << 1,
    TableSectionDestination  = 1UL << 2,
    TableSectionUsage        = 1UL << 3,
    TableSectionSubscription = 1UL << 4,
    TableSectionArea         = 1UL << 5,    // The optional state will be placed in a row here.
    TableSectionAddress      = 1UL << 6,
} TableSections;

typedef enum
{
    AreaRowType                = 1UL << 0,
    AreaRowAreaCode            = 1UL << 1,
    AreaRowAreaName            = 1UL << 2,
    AreaRowStateName           = 1UL << 3,
    AreaRowCountry             = 1UL << 4,
} AreaRows;


@interface NumberViewController ()
{
    NumberData*   number;
    
    TableSections sections;
    AreaRows      areaRows;
}

@end


@implementation NumberViewController

- (instancetype)initWithNumber:(NumberData*)theNumber
          managedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    if (self = [super initWithManagedObjectContext:managedObjectContext])
    {
        number    = theNumber;
        self.name = number.name;

        self.title = NSLocalizedStringWithDefaultValue(@"Number:NumberDetails ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"Number",
                                                       @"Title of app screen with details of a phone number\n"
                                                       @"[1 line larger font].");

        // Mandatory sections.
        sections |= TableSectionName;
        sections |= TableSectionE164;
        sections |= TableSectionDestination;
        sections |= TableSectionUsage;
        
        sections |= TableSectionArea;
        sections |= TableSectionSubscription;

        // Optional sections.
        sections |= (number.address != nil) ? TableSectionAddress : 0;

        // Area Rows
        areaRows |= AreaRowType;
        areaRows |= AreaRowAreaCode;
        areaRows |= (number.areaName  != nil) ? AreaRowAreaName  : 0;
        areaRows |= (number.stateName != nil) ? AreaRowStateName : 0;
        areaRows |= AreaRowCountry;

        self.nameIndexPath = [NSIndexPath indexPathForRow:0 inSection:[Common nOfBit:TableSectionName inValue:sections]];
    }

    return self;
}


#pragma mark - Table View Delegates

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* title = nil;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionSubscription:
        {
            title = NSLocalizedStringWithDefaultValue(@"Number:Subscription SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Subscription",
                                                      @"....");
            break;
        }
        case TableSectionArea:
        {
            title = [Strings detailsString];
            break;
        }
        case TableSectionAddress:
        {
            title = NSLocalizedStringWithDefaultValue(@"Number:Name SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Contact Address",
                                                      @"....");
            break;
        }
    }

    return title;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString* title = nil;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionName:
        {
            title = NSLocalizedStringWithDefaultValue(@"Number:Name SectionFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"Tap to edit. A change will also be saved "
                                                      @"online. Refresh the overview Numbers list on other "
                                                      @"devices to load changes.",
                                                      @"[* lines]");
            break;
        }
        case TableSectionDestination:
        {
            title = NSLocalizedStringWithDefaultValue(@"Number:DestinationDefault SectionFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"With 'Default' all devices associated with this number "
                                                      @"will ring when an incoming call is received.",
                                                      @"Explanation about which phone will be called.\n"
                                                      @"[* lines]");
            break;
        }
        case TableSectionSubscription:
        {
            title = NSLocalizedStringWithDefaultValue(@"Number:Subscription SectionFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"IMPORTANT: If you don't extend this subscription in time, "
                                                      @"your Number can't be used anymore after it expires. Once "
                                                      @"expired a Number can often not be reactivated.",
                                                      @"Explanation how/when the subscription, for "
                                                      @"using a phone number, will expire\n"
                                                      @"[* lines]");
            break;
        }
    }

    return title;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return [Common bitsSetCount:sections];
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionName:         numberOfRows = 1;                              break;
        case TableSectionE164:         numberOfRows = 1;                              break;
        case TableSectionDestination:  numberOfRows = 1;                              break;
        case TableSectionUsage:        numberOfRows = 1;                              break;
        case TableSectionSubscription: numberOfRows = 3;                              break;  // Second row leads to buying extention.
        case TableSectionArea:         numberOfRows = [Common bitsSetCount:areaRows]; break;
        case TableSectionAddress:      numberOfRows = 1;                              break;
    }

    return numberOfRows;
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    NumberDestinationsViewController* destinationsViewController;

    if ([self.tableView cellForRowAtIndexPath:indexPath].selectionStyle == UITableViewCellSelectionStyleNone)
    {
        return;
    }

    switch ([Common nthBitSet:indexPath.section inValue:sections])
    {
        case TableSectionName:
        {
            break;
        }
        case TableSectionE164:
        {
            break;
        }
        case TableSectionDestination:
        {
            destinationsViewController = [[NumberDestinationsViewController alloc] initWithNumber:number];
            [self.navigationController pushViewController:destinationsViewController animated:YES];
            break;
        }
        case TableSectionUsage:
        {
            [Settings sharedSettings].callerIdE164 = number.e164;

            UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            break;
        }
        case TableSectionSubscription:
        {
            break;
        }
        case TableSectionArea:
        {
            break;
        }
        case TableSectionAddress:
        {
            //###
            break;
        }
    }
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = nil;
    NSString*        identifier;

    switch ([Common nthBitSet:indexPath.section inValue:sections])
    {
        case TableSectionName:
        {
            return [self nameCellForRowAtIndexPath:indexPath];
            // identifier         = @"TextFieldCell";
            // self.nameIndexPath = indexPath;
            break;
        }
        case TableSectionE164:
        {
            identifier = @"NumberCell";
            break;
        }
        case TableSectionDestination:
        {
            identifier = @"DisclosureCell";
            break;
        }
        case TableSectionUsage:
        {
            identifier = @"UsageCell";
        }
        case TableSectionSubscription:
        {
            identifier = @[@"Value1Cell", @"DisclosureCell", @"RenewCell"][indexPath.row];
            break;
        }
        case TableSectionArea:
        {
            if ([Common nthBitSet:indexPath.row inValue:areaRows] == AreaRowCountry)
            {
                identifier = @"CountryCell";
            }
            else
            {
                identifier = @"Value1Cell";
            }
            break;
        }
        case TableSectionAddress:
        {
            identifier = @"AddressCell";
            break;
        }
    }

    cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];

        if ([identifier isEqualToString:@"RenewCell"])
        {
            UISwitch* switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
            switchView.onTintColor = [Skinning onTintColor];
            cell.accessoryView = switchView;

            [switchView addTarget:self
                           action:@selector(autoRenewSwitchAction:)
                 forControlEvents:UIControlEventValueChanged];
        }
    }

    return cell;
}


- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    switch ([Common nthBitSet:indexPath.section inValue:sections])
    {
        case TableSectionName:
        {
            //###[self updateNameCell:cell atIndexPath:indexPath];
            break;
        }
        case TableSectionE164:
        {
            [self updateNumberCell:cell];
            break;
        }
        case TableSectionDestination:
        {
            [self updateDestinationCell:cell];
            break;
        }
        case TableSectionUsage:
        {
            [self updateUsageCell:cell];
            break;
        }
        case TableSectionSubscription:
        {
            [self updateSubscriptionCell:cell atIndexPath:indexPath];
            break;
        }
        case TableSectionArea:
        {
            [self updateAreaCell:cell atIndexPath:indexPath];
            break;
        }
        case TableSectionAddress:
        {
            //###[self updateContactAddressCell:cell atIndexPath:indexPath];
            break;
        }
    }
}


#pragma mark - Actions

- (void)autoRenewSwitchAction:(UISwitch*)switchView
{
    [[WebClient sharedClient] updateNumberE164:number.e164
                                      withName:number.name
                                     autoRenew:switchView.isOn
                                         reply:^(NSError* error)
    {
        if (error == nil)
        {
            number.name      = self.name;
            number.autoRenew = switchView.isOn;

            [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];

            NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:[Common nOfBit:TableSectionSubscription
                                                                        inValue:sections]];
            [self.tableView beginUpdates];
            [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
        else
        {
            self.name = number.name;
            [self showAutoRenewSaveError:error];
        }
    }];
}


#pragma mark - Cell Methods

- (void)updateNameCell:(UITableViewCell*)cell
{
    UITextField* textField;

    textField = (UITextField*)[cell viewWithTag:CommonTextFieldCellTag];
    if (textField == nil)
    {
        textField = [Common addTextFieldToCell:cell delegate:self];
        textField.tag = CommonTextFieldCellTag;
        textField.enablesReturnKeyAutomatically = YES;
    }

    textField.placeholder            = [Strings requiredString];
    textField.text                   = self.name;
    textField.userInteractionEnabled = YES;

    cell.selectionStyle              = UITableViewCellSelectionStyleNone;
    cell.textLabel.text              = [Strings nameString];

    if (self.name.length == 0)
    {
        [textField becomeFirstResponder];
    }
}


- (void)updateNumberCell:(UITableViewCell*)cell
{
    NumberLabel* numberLabel = [Common addNumberLabelToCell:cell];

    numberLabel.text         = [[PhoneNumber alloc] initWithNumber:number.e164].internationalFormat;
    [Common addCountryImageToCell:cell isoCountryCode:number.isoCountryCode];
    cell.selectionStyle      = UITableViewCellSelectionStyleNone;
}


- (void)updateDestinationCell:(UITableViewCell*)cell
{
    cell.textLabel.text       = NSLocalizedStringWithDefaultValue(@"Number Destination", nil,
                                                                  [NSBundle mainBundle], @"Destination",
                                                                  @"....");
    cell.textLabel.textColor  = [UIColor blackColor];
    cell.detailTextLabel.text = (number.destination == nil) ? [Strings defaultString] : number.destination.name;
    cell.selectionStyle       = UITableViewCellSelectionStyleDefault;
    cell.accessoryType        = UITableViewCellAccessoryDisclosureIndicator;
}


- (void)updateUsageCell:(UITableViewCell*)cell
{
    cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Settings:UseDefaultCallerId CellText", nil,
                                                            [NSBundle mainBundle], @"Use As Default Caller ID",
                                                            @"..."
                                                            @"[....");
    if ([[Settings sharedSettings].callerIdE164 isEqualToString:number.e164])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }

    cell.textLabel.textColor = [Skinning tintColor];
}


- (void)updateSubscriptionCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    NSString*        dateFormat    = [NSDateFormatter dateFormatFromTemplate:@"E MMM d yyyy"
                                                                     options:0
                                                                      locale:[NSLocale currentLocale]];
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:dateFormat];
    [dateFormatter setLocale:[NSLocale currentLocale]];

    switch (indexPath.row)
    {
        case 0:
        {
            cell.textLabel.text       = NSLocalizedStringWithDefaultValue(@"Number:SubscriptionPurchaseDate Label", nil,
                                                                          [NSBundle mainBundle], @"Purchase",
                                                                          @"....");
            cell.detailTextLabel.text = [dateFormatter stringFromDate:number.purchaseDate];
            cell.selectionStyle       = UITableViewCellSelectionStyleNone;
            break;
        }
        case 1:
        {
            if (number.autoRenew)
            {
                cell.textLabel.text   = NSLocalizedStringWithDefaultValue(@"Number:SubscriptionRenewalDate Label", nil,
                                                                          [NSBundle mainBundle], @"Renewal",
                                                                          @"....");
            }
            else
            {
                cell.textLabel.text   = NSLocalizedStringWithDefaultValue(@"Number:SubscriptionRenewalDate Label", nil,
                                                                          [NSBundle mainBundle], @"Expiry",
                                                                          @"....");
            }

            cell.detailTextLabel.text = [dateFormatter stringFromDate:number.renewalDate];
            cell.accessoryType        = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle       = UITableViewCellSelectionStyleDefault;
            break;
        }
        case 2:
        {
            cell.textLabel.text       = NSLocalizedStringWithDefaultValue(@"Number:SubscriptionRenewalChoice Label", nil,
                                                                          [NSBundle mainBundle], @"Renew Automatically",
                                                                          @"....");
            UISwitch* switchView = (UISwitch*)cell.accessoryView;
            switchView.on = number.autoRenew;
            break;
        }
    }
}


- (void)updateAreaCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    NumberTypeMask numberTypeMask;
    switch ([Common nthBitSet:indexPath.row inValue:areaRows])
    {
        case AreaRowType:
        {
            cell.textLabel.text       = [Strings typeString];
            numberTypeMask            = [NumberType numberTypeMaskForString:number.numberType];
            cell.detailTextLabel.text = [NumberType localizedStringForNumberTypeMask:numberTypeMask];
            break;
        }
        case AreaRowAreaCode:
        {
            cell.textLabel.text       = [Strings areaCodeString];
            cell.detailTextLabel.text = number.areaCode;
            break;
        }
        case AreaRowAreaName:
        {
            cell.textLabel.text       = [Strings areaString];
            cell.detailTextLabel.text = number.areaName;
            break;
        }
        case AreaRowStateName:
        {
            cell.textLabel.text       = [Strings stateString];
            cell.detailTextLabel.text = number.stateName;
            break;
        }
        case AreaRowCountry:
        {
            cell.textLabel.text       = [Strings countryString];
            cell.detailTextLabel.text = [[CountryNames sharedNames] nameForIsoCountryCode:number.isoCountryCode];
            break;
        }
    }

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType  = UITableViewCellAccessoryNone;
}


#pragma mark - Baseclass Override

- (void)save
{
    if ([self.name isEqualToString:number.name] == YES)
    {
        return;
    }

    [[WebClient sharedClient] updateNumberE164:number.e164
                                      withName:self.name
                                     autoRenew:number.autoRenew
                                         reply:^(NSError* error)
    {
        if (error == nil)
        {
            number.name = self.name;

            [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];
        }
        else
        {
            self.name = number.name;
            [self showNameSaveError:error];
        }
    }];
}


- (void)showNameSaveError:(NSError*)error
{
    NSString* title;
    NSString* message;
    
    title   = NSLocalizedStringWithDefaultValue(@"Number NameUpdateFailedTitle", nil,
                                                [NSBundle mainBundle], @"Name Not Updated",
                                                @"Alert title telling that a name was not saved.\n"
                                                @"[iOS alert title size].");
    message = NSLocalizedStringWithDefaultValue(@"Number NameUpdateFailedMessage", nil,
                                                [NSBundle mainBundle],
                                                @"Saving the name failed: %@\n\n"
                                                @"Please try again later.",
                                                @"Alert message telling that a name must be supplied\n"
                                                @"[iOS alert message size]");
    message = [NSString stringWithFormat:message, error.localizedDescription];
    [BlockAlertView showAlertViewWithTitle:title
                                   message:message
                                completion:^(BOOL cancelled, NSInteger buttonIndex)
    {
        self.name = number.name;
        [self updateNameCell:[self.tableView cellForRowAtIndexPath:self.nameIndexPath]];
     }
                         cancelButtonTitle:[Strings closeString]
                         otherButtonTitles:nil];
}


- (void)showAutoRenewSaveError:(NSError*)error
{
    NSString* title;
    NSString* message;

    title   = NSLocalizedStringWithDefaultValue(@"Number AutoRenewUpdateFailedTitle", nil,
                                                [NSBundle mainBundle], @"Auto Renew Not Updated",
                                                @"Alert title telling that a setting was not saved.\n"
                                                @"[iOS alert title size].");
    message = NSLocalizedStringWithDefaultValue(@"Number AutoRenewUpdateFailedMessage", nil,
                                                [NSBundle mainBundle],
                                                @"Saving the auto renew setting failed: %@\n\n"
                                                @"Please try again later.",
                                                @"Alert message telling that a setting must be supplied\n"
                                                @"[iOS alert message size]");
    message = [NSString stringWithFormat:message, error.localizedDescription];
    [BlockAlertView showAlertViewWithTitle:title
                                   message:message
                                completion:^(BOOL cancelled, NSInteger buttonIndex)
    {
        NSInteger        section    = [Common nOfBit:TableSectionSubscription inValue:sections];
        NSIndexPath*     indexPath  = [NSIndexPath indexPathForItem:2 inSection:section];
        UITableViewCell* cell       = [self.tableView cellForRowAtIndexPath:indexPath];
        UISwitch*        switchView = (UISwitch*)cell.accessoryView;

        [switchView setOn:number.autoRenew animated:YES];
    }
                         cancelButtonTitle:[Strings closeString]
                         otherButtonTitles:nil];
}

@end
