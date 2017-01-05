//
//  NumberViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 27/03/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "NumberViewController.h"
#import "NumberDestinationsViewController.h"
#import "IncomingChargesViewController.h"
#import "NumberExtendViewController.h"
#import "NumbersViewController.h"
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
#import "AddressData.h"
#import "PurchaseManager.h"
#import "NetworkStatus.h"
#import "AppDelegate.h"
#import "PhoneData.h"


typedef enum
{
    TableSectionName        = 1UL << 0,
    TableSectionInfo        = 1UL << 1,
    TableSectionDestination = 1UL << 2,
    TableSectionUsage       = 1UL << 3,
    TableSectionPeriod      = 1UL << 4,
    TableSectionAddress     = 1UL << 5,
    TableSectionCharges     = 1UL << 6,
} TableSections;

typedef enum
{
    InfoRowE164 = 1UL << 0,
    InfoRowArea = 1UL << 1,
} InfoRows;


@interface NumberViewController ()
{
    NumberData*   number;
    
    TableSections sections;
    InfoRows      infoRows;
    BOOL          isLoadingAddress;
    NSIndexPath*  expiryIndexPath;
    id            reachabilityObserver;
}

@property (nonatomic, strong) NSPredicate* addressesPredicate;

@end


@implementation NumberViewController

- (instancetype)initWithNumber:(NumberData*)theNumber
          managedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    if (self = [super initWithManagedObjectContext:managedObjectContext])
    {
        number = theNumber;

        self.title = NSLocalizedStringWithDefaultValue(@"Number:NumberDetails ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"Number",
                                                       @"Title of app screen with details of a phone number\n"
                                                       @"[1 line larger font].");

        // Mandatory sections.
        sections |= TableSectionName;
        sections |= TableSectionInfo;
        sections |= TableSectionDestination;
        sections |= TableSectionAddress;

        // Optional section.
        sections |= [number isPending] ? 0 : TableSectionUsage;
        sections |= [number isPending] ? 0 : TableSectionPeriod;
        sections |= [IncomingChargesViewController hasIncomingChargesWithNumber:number] ? TableSectionCharges : 0;

        // Info Rows
        infoRows |= InfoRowE164;
        infoRows |= InfoRowArea;

        NSInteger section  = [Common nOfBit:TableSectionName inValue:sections];
        self.nameIndexPath = [NSIndexPath indexPathForRow:0 inSection:section];

        self.item = theNumber;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    [self loadAddressesPredicate];

    __weak typeof(self) weakSelf = self;
    reachabilityObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NetworkStatusReachableNotification
                                                                             object:nil
                                                                              queue:[NSOperationQueue mainQueue]
                                                                         usingBlock:^(NSNotification* note)
    {
        if (weakSelf.addressesPredicate == nil && [note.userInfo[@"status"] boolValue])
        {
            [weakSelf loadAddressesPredicate];
        }
    }];
}


- (void)viewWillDisppear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self.tableView endEditing:YES];
}


- (void)dealloc
{
    [AddressesViewController cancelLoadingAddressPredicate];

    [[NSNotificationCenter defaultCenter] removeObserver:reachabilityObserver];
}


#pragma mark - Table View Delegates

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* title = nil;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionPeriod:
        {
            title = NSLocalizedStringWithDefaultValue(@"Number:Period SectionHeader", nil, [NSBundle mainBundle],
                                                      @"Usage Period",
                                                      @"....");
            break;
        }
        case TableSectionAddress:
        {
            title = NSLocalizedStringWithDefaultValue(@"Number:Name SectionHeader", nil, [NSBundle mainBundle],
                                                      @"Contact Address",
                                                      @"....");
            break;
        }
    }

    return title;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString* title = nil;

    if (self.showFootnotes == NO)
    {
        return nil;
    }

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionPeriod:
        {
            title = NSLocalizedStringWithDefaultValue(@"Number:Period SectionFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"IMPORTANT: If you don't renew in time, your Number "
                                                      @"can not be used anymore after it expires. Once "
                                                      @"expired, a Number can not be reactivated.",
                                                      @"Explanation how/when the subscription, for "
                                                      @"using a phone number, will expire\n"
                                                      @"[* lines]");
            break;
        }
        case TableSectionAddress:
        {
            //### Write more when it's a required Address, saying the Number is used 'illegally'.
            title = NSLocalizedStringWithDefaultValue(@"Number:Address SectionFooter", nil, [NSBundle mainBundle],
                                                      @"Create a new Address when you move, assign it to "
                                                      @"the Numbers that use it, and then delete the old Address.",
                                                      @"\n"
                                                      @"[* lines]");
            break;
        }
        case TableSectionCharges:
        {
            title = NSLocalizedStringWithDefaultValue(@"Number:Charges SectionFooter", nil, [NSBundle mainBundle],
                                                      @"When someone calls you at this Number, additional "
                                                      @"charges apply.",
                                                      @"....");
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
        case TableSectionName:        numberOfRows = 1;                              break;
        case TableSectionInfo:        numberOfRows = [Common bitsSetCount:infoRows]; break;
        case TableSectionDestination: numberOfRows = 1;                              break;
        case TableSectionUsage:       numberOfRows = 1;                              break;
        case TableSectionPeriod:      numberOfRows = 3;                              break;  //### No Auto Renew for now.
        case TableSectionAddress:     numberOfRows = 1;                              break;
        case TableSectionCharges:     numberOfRows = 1;                              break;
    }

    return numberOfRows;
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    if ([number hasExpired])
    {
        [self.navigationController popViewControllerAnimated:YES];

        return;
    }

    NumberDestinationsViewController* destinationsViewController;
    IncomingChargesViewController*    chargesViewController;
    UITableViewCell*                  cell;

    cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (cell.selectionStyle == UITableViewCellSelectionStyleNone)
    {
        return;
    }

    switch ([Common nthBitSet:indexPath.section inValue:sections])
    {
        case TableSectionDestination:
        {
            destinationsViewController = [[NumberDestinationsViewController alloc] initWithNumber:number];
            [self.navigationController pushViewController:destinationsViewController animated:YES];
            break;
        }
        case TableSectionUsage:
        {
            [Common checkCallerIdUsageOfNumber:number completion:^(BOOL canUse)
            {
                if (canUse)
                {
                    [Settings sharedSettings].callerIdE164 = number.e164;

                    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                }
                else
                {
                    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                }
            }];
            break;
        }
        case TableSectionPeriod:
        {
            NumberExtendViewController* extendViewController;

            extendViewController = [[NumberExtendViewController alloc] initWithNumber:number
                                                                           completion:^
            {
                UITableViewCell* expiryCell = [self.tableView cellForRowAtIndexPath:expiryIndexPath];
                [self tableView:self.tableView willDisplayCell:expiryCell forRowAtIndexPath:expiryIndexPath];

                [[AppDelegate appDelegate] updateNumbersBadgeValue];
                [[AppDelegate appDelegate] refreshLocalNotifications];
            }];

            extendViewController.title = cell.textLabel.text;
            [self.navigationController pushViewController:extendViewController animated:YES];
            break;
        }
        case TableSectionAddress:
        {
            NSManagedObjectContext*  managedObjectContext = [DataManager sharedManager].managedObjectContext;
            AddressesViewController* viewController;
            NumberTypeMask           numberTypeMask  = [NumberType numberTypeMaskForString:number.numberType];
            AddressTypeMask          addressTypeMask = [AddressType addressTypeMaskForString:number.addressType];

            viewController = [[AddressesViewController alloc] initWithManagedObjectContext:managedObjectContext
                                                                           selectedAddress:number.address
                                                                            isoCountryCode:number.isoCountryCode
                                                                                  areaCode:number.areaCode
                                                                                numberType:numberTypeMask
                                                                               addressType:addressTypeMask
                                                                                proofTypes:number.proofTypes
                                                                                 predicate:self.addressesPredicate
                                                                                completion:^(AddressData *selectedAddress)
            {
                if (selectedAddress != number.address)
                {
                    self.isLoading = YES;
                    [[WebClient sharedClient] updateNumberWithUuid:number.uuid
                                                              name:number.name
                                                         autoRenew:number.autoRenew
                                                         addressId:selectedAddress.addressId
                                                             reply:^(NSError* error)
                    {
                        self.isLoading = NO;
                        if (error == nil)
                        {
                            number.address = selectedAddress;
                            [self reloadAddressCell];
                        }
                        else
                        {
                            NSString* title = NSLocalizedStringWithDefaultValue(@"Number AutoRenewUpdateFailedTitle", nil,
                                                                                [NSBundle mainBundle], @"Address Not Updated",
                                                                                @"Alert title telling that a setting was not saved.\n"
                                                                                @"[iOS alert title size].");

                            [self showSaveError:error title:title itemName:[Strings numberString] completion:^
                            {
                                //### Need to do something here???
                            }];
                        }
                    }];
                }
            }];

            [self.navigationController pushViewController:viewController animated:YES];
            break;
        }
        case TableSectionCharges:
        {
            chargesViewController       = [[IncomingChargesViewController alloc] initWithNumber:number];
            chargesViewController.title = cell.textLabel.text;
            [self.navigationController pushViewController:chargesViewController animated:YES];
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
        }
        case TableSectionInfo:
        {
            switch ([Common nthBitSet:indexPath.row inValue:infoRows])
            {
                case InfoRowE164: identifier = @"E164Cell"; break;
                case InfoRowArea: identifier = @"AreaCell"; break;
            }
            break;
        }
        case TableSectionDestination:
        {
            identifier = @"DestinationCell";
            break;
        }
        case TableSectionUsage:
        {
            identifier = @"UsageCell";
            break;
        }
        case TableSectionPeriod:
        {
            identifier = @[@"Value1Cell", @"Value1Cell", @"DisclosureCell", @"RenewCell"][indexPath.row];
            break;
        }
        case TableSectionAddress:
        {
            identifier = @"AddressCell";
            break;
        }
        case TableSectionCharges:
        {
            identifier = @"DisclosureCell";
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
        case TableSectionInfo:
        {
            switch ([Common nthBitSet:indexPath.row inValue:infoRows])
            {
                case InfoRowE164: [self updateInfoE164Cell:cell]; break;
                case InfoRowArea: [self updateInfoAreaCell:cell]; break;
            }
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
        case TableSectionPeriod:
        {
            [self updatePeriodCell:cell atIndexPath:indexPath];
            break;
        }
        case TableSectionAddress:
        {
            [self updateAddressCell:cell atIndexPath:indexPath];
            break;
        }
        case TableSectionCharges:
        {
            [self updateChargeCell:cell atIndexPath:indexPath];
            break;
        }
    }
}


#pragma mark - Actions

- (void)autoRenewSwitchAction:(UISwitch*)switchView
{
    self.isLoading = YES;
    [[WebClient sharedClient] updateNumberWithUuid:number.uuid
                                              name:number.name
                                         autoRenew:switchView.isOn
                                         addressId:number.address.addressId
                                             reply:^(NSError* error)
    {
        self.isLoading = NO;
        if (error == nil)
        {
            number.autoRenew = switchView.isOn;

            [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];

            [Common reloadSections:TableSectionPeriod allSections:sections tableView:self.tableView];
        }
        else
        {
            NSString* title = NSLocalizedStringWithDefaultValue(@"Number AutoRenewUpdateFailedTitle", nil,
                                                                [NSBundle mainBundle], @"Auto Renew Not Updated",
                                                                @"Alert title telling that a setting was not saved.\n"
                                                                @"[iOS alert title size].");

            [self showSaveError:error title:title itemName:[Strings numberString] completion:^
            {
                NSInteger        section    = [Common nOfBit:TableSectionPeriod inValue:sections];
                NSIndexPath*     indexPath  = [NSIndexPath indexPathForItem:2 inSection:section];
                UITableViewCell* cell       = [self.tableView cellForRowAtIndexPath:indexPath];
                UISwitch*        switchView = (UISwitch*)cell.accessoryView;

                [switchView setOn:number.autoRenew animated:YES];
            }];
        }
    }];
}


#pragma mark - Cell Methods

- (void)updateInfoE164Cell:(UITableViewCell*)cell
{
    NumberLabel*   numberLabel    = [Common addNumberLabelToCell:cell];
    NumberTypeMask numberTypeMask = [NumberType numberTypeMaskForString:number.numberType];

    if ([number isPending])
    {
        numberLabel.text = [Strings pendingString];
    }
    else
    {
        PhoneNumber*               phoneNumber      = [[PhoneNumber alloc] initWithNumber:number.e164];
        NSString*                  string           = phoneNumber.internationalFormat;
        NSMutableAttributedString* attributedString = [[NSMutableAttributedString alloc] initWithString:string];

        UIFont*           font       = numberLabel.font;
        UIFontDescriptor* descriptor = [[font fontDescriptor] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
        UIFont*           boldFont   = [UIFont fontWithDescriptor:descriptor size:font.pointSize];

        NSRange range;
        if (number.areaCode.length > 0)
        {
            range = NSMakeRange(0, 1 + phoneNumber.callCountryCode.length + 1 + number.areaCode.length);
        }
        else
        {
            range = NSMakeRange(0, 1 + phoneNumber.callCountryCode.length);
        }

        [attributedString addAttribute:NSFontAttributeName value:boldFont range:range];
        
        numberLabel.attributedText = attributedString;
    }

    cell.textLabel.text = [NumberType localizedStringForNumberTypeMask:numberTypeMask];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
}


- (void)updateInfoAreaCell:(UITableViewCell*)cell
{
    cell.imageView.image      = [UIImage imageNamed:number.isoCountryCode];
    cell.detailTextLabel.text = [self areaName];
    cell.selectionStyle       = UITableViewCellSelectionStyleNone;
}


- (void)updateDestinationCell:(UITableViewCell*)cell
{
    if (number.destination == nil)
    {
        cell.textLabel.text            = nil;
        cell.textLabel.attributedText  = [Common strikethroughAttributedString:[Strings destinationString]];
        cell.detailTextLabel.text      = [Strings noneString];
        cell.detailTextLabel.textColor = [Skinning deleteTintColor];
    }
    else
    {
        cell.textLabel.attributedText  = nil;
        cell.textLabel.text            = [Strings destinationString];
        cell.detailTextLabel.text      = [number.destination defaultName];
        cell.detailTextLabel.textColor = [Skinning valueColor];
    }

    cell.textLabel.textColor = [UIColor blackColor];
    cell.selectionStyle      = UITableViewCellSelectionStyleDefault;
    cell.accessoryType       = UITableViewCellAccessoryDisclosureIndicator;
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


- (void)updatePeriodCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    cell.detailTextLabel.textColor = [Skinning valueColor]; // Make sure this is the default.
    switch (indexPath.row)
    {
        case 0:
        {
            cell.textLabel.text       = NSLocalizedStringWithDefaultValue(@"Number:PeriodPurchaseDate Label", nil,
                                                                          [NSBundle mainBundle], @"Purchase",
                                                                          @"....");
            cell.detailTextLabel.text = [number purchaseDateString];
            cell.selectionStyle       = UITableViewCellSelectionStyleNone;
            break;
        }
        case 1:
        {
            cell.textLabel.text       = NSLocalizedStringWithDefaultValue(@"Number:PeriodRenewalDate Label", nil,
                                                                          [NSBundle mainBundle], @"Expiry",
                                                                          @"....");
            cell.detailTextLabel.text = [number expiryDateString];
            cell.selectionStyle       = UITableViewCellSelectionStyleNone;

            if ([number isExpiryCritical])
            {
                cell.detailTextLabel.textColor = [Skinning deleteTintColor];    // Overrides the default color.
            }

            expiryIndexPath = indexPath;
            break;
        }
        case 2:
        {
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Number:PeriodRenewal Label", nil,
                                                                    [NSBundle mainBundle], @"Buy Extension",
                                                                    @"....");
            cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;

            NSString* monthPriceString = [[PurchaseManager sharedManager] localizedFormattedPrice:number.monthFee];
            cell.detailTextLabel.text      = [NSString stringWithFormat:@"%@/%@", monthPriceString, [Strings monthString]];
            cell.detailTextLabel.textColor = [Skinning priceColor];
            break;
        }
        case 3:
        {
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Number:PeriodRenewalChoice Label", nil,
                                                                    [NSBundle mainBundle], @"Renew Automatically",
                                                                    @"....");
            UISwitch* switchView = (UISwitch*)cell.accessoryView;
            switchView.on = number.autoRenew;
            break;
        }
    }
}


- (void)updateAddressCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    cell.detailTextLabel.textColor = number.address ? [Skinning valueColor] : [Skinning placeholderColor];

    if (isLoadingAddress)
    {
        UIActivityIndicatorView* spinner;
        spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [spinner startAnimating];

        cell.accessoryView = spinner;
    }
    else
    {
        cell.accessoryView = nil;
    }

    cell.textLabel.text         = [Strings addressString];
    cell.detailTextLabel.text   = number.address ? number.address.name : [Strings requiredString];
    cell.accessoryType          = (self.addressesPredicate != nil) ? UITableViewCellAccessoryDisclosureIndicator
                                                                   : UITableViewCellAccessoryNone;
    cell.userInteractionEnabled = (self.addressesPredicate != nil); // Must be set last, otherwise setting colors does not work.
}


- (void)updateChargeCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    cell.accessoryType        = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text       = [Strings incomingChargesString];
    cell.detailTextLabel.text = @"";
}


#pragma mark - Helpers

- (void)loadAddressesPredicate
{
    self.addressesPredicate = nil;
    isLoadingAddress        = YES;
    [self reloadAddressCell];

    AddressTypeMask addressTypeMask = [AddressType addressTypeMaskForString:number.addressType];
    NumberTypeMask  numberTypeMask  = [NumberType numberTypeMaskForString:number.numberType];
    [AddressesViewController loadAddressesPredicateWithAddressType:addressTypeMask
                                                    isoCountryCode:number.isoCountryCode
                                                          areaCode:number.areaCode
                                                        numberType:numberTypeMask
                                                      areAvailable:YES
                                                        completion:^(NSPredicate *predicate, NSError *error)
    {
        isLoadingAddress = NO;
        if (error == nil)
        {
            self.addressesPredicate = predicate;
            [self reloadAddressCell];
        }
        else
        {
            [self showError:error];
        }
    }];
}


- (void)reloadAddressCell
{
    NSArray* indexPaths = @[[NSIndexPath indexPathForItem:0
                                                inSection:[Common nOfBit:TableSectionAddress inValue:sections]]];

    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}


- (void)showError:(NSError*)error
{
    NSString* title;
    NSString* message;

    title   = NSLocalizedStringWithDefaultValue(@"NumberArea LoadFailAlertTitle", nil,
                                                [NSBundle mainBundle], @"Loading Failed",
                                                @"Alert title telling that loading addresses over internet failed.\n"
                                                @"[iOS alert title size].");
    message = NSLocalizedStringWithDefaultValue(@"NumberArea LoadFailAlertMessage", nil,
                                                [NSBundle mainBundle],
                                                @"Loading the list of valid (alternative) addresses for this "
                                                @"Number failed: %@\n\n"
                                                @"Please try again later if you want to change the Address.",
                                                @"Alert message telling that loading areas over internet failed.\n"
                                                @"[iOS alert message size!]");
    message = [NSString stringWithFormat:message, error.localizedDescription];
    [BlockAlertView showAlertViewWithTitle:title
                                   message:message
                                completion:^(BOOL cancelled, NSInteger buttonIndex)
    {
        [self reloadAddressCell];
    }
                         cancelButtonTitle:[Strings closeString]
                         otherButtonTitles:nil];
}


- (NSString*)areaName
{
    if (number.areaName.length > 0)
    {
        if (number.stateCode.length > 0)
        {
            return [NSString stringWithFormat:@"%@  %@", number.areaName, number.stateCode];
        }
        else
        {
            return number.areaName;
        }
    }
    else
    {
        return [[CountryNames sharedNames] nameForIsoCountryCode:number.isoCountryCode];
    }
}


#pragma mark - Baseclass Override

- (void)save
{
    if (number.changedValues.count == 0)
    {
        return;
    }

    self.isLoading = YES;
    [[WebClient sharedClient] updateNumberWithUuid:number.uuid
                                              name:number.name
                                         autoRenew:number.autoRenew
                                         addressId:number.address.addressId
                                             reply:^(NSError* error)
    {
        self.isLoading = NO;

        if (error == nil)
        {
            [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];
        }
        else
        {
            [self showSaveError:error title:nil itemName:[Strings numberString] completion:^
            {
                [number.managedObjectContext refreshObject:number mergeChanges:NO];
                [Common reloadSections:sections allSections:sections tableView:self.tableView];
            }];
        }
    }];
}

@end
