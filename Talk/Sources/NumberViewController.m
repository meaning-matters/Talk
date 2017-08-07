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
#import "BlockActionSheet.h"


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
    TableSections sections;
    InfoRows      infoRows;
    BOOL          isLoadingAddress;
    NSIndexPath*  expiryIndexPath;
    id            reachabilityObserver;

    BOOL          isDeleting;
}

@property (nonatomic, strong) NumberData*  number;
@property (nonatomic, strong) NSPredicate* addressesPredicate;

@end


@implementation NumberViewController

- (instancetype)initWithNumber:(NumberData*)number
          managedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    if (self = [super initWithManagedObjectContext:managedObjectContext])
    {
        self.number = number;

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
        sections |= self.number.isPending ? 0 : TableSectionUsage;
        sections |= self.number.isPending ? 0 : TableSectionPeriod;
        sections |= [IncomingChargesViewController hasIncomingChargesWithNumber:number] ? TableSectionCharges : 0;

        // Info Rows
        infoRows |= InfoRowE164;
        infoRows |= InfoRowArea;

        NSInteger section  = [Common nOfBit:TableSectionName inValue:sections];
        self.nameIndexPath = [NSIndexPath indexPathForRow:0 inSection:section];

        self.item = number;
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

    UIBarButtonItem* buttonItem;
    buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                               target:self
                                                               action:@selector(deleteAction)];
    self.navigationItem.rightBarButtonItem = buttonItem;
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
    if (!self.number.isPending && [self.number hasExpired])
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
        case TableSectionInfo:
        {
            NSString* title   = NSLocalizedString(@"Pending Activation", @"");
            NSString* message = NSLocalizedString(@"The Address you created or selected, needs to be verified. %@\n\n"
                                                  @"When verification is successful, your Number will be activated "
                                                  @"automatically. You will then see your new telephone number.",
                                                  @"");
            message = [NSString stringWithFormat:message, [Strings addressVerificationPhraseString]];

            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
            {
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            }
                                 cancelButtonTitle:[Strings closeString]
                                 otherButtonTitles:nil];
            break;
        }
        case TableSectionDestination:
        {
            destinationsViewController = [[NumberDestinationsViewController alloc] initWithNumber:self.number];
            [self.navigationController pushViewController:destinationsViewController animated:YES];
            break;
        }
        case TableSectionUsage:
        {
            [Common checkCallerIdUsageOfNumber:self.number completion:^(BOOL canUse)
            {
                if (canUse)
                {
                    [Settings sharedSettings].callerIdE164 = self.number.e164;

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

            extendViewController = [[NumberExtendViewController alloc] initWithNumber:self.number
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
            NumberTypeMask           numberTypeMask  = [NumberType numberTypeMaskForString:self.number.numberType];
            AddressTypeMask          addressTypeMask = [AddressType addressTypeMaskForString:self.number.addressType];

            viewController = [[AddressesViewController alloc] initWithManagedObjectContext:managedObjectContext
                                                                           selectedAddress:self.number.address
                                                                            isoCountryCode:self.number.isoCountryCode
                                                                                  areaCode:self.number.areaCode
                                                                                    areaId:self.number.areaId
                                                                                      city:nil
                                                                                numberType:numberTypeMask
                                                                               addressType:addressTypeMask
                                                                                 predicate:self.addressesPredicate
                                                                                isVerified:self.number.isPending ? NO : YES
                                                                                completion:^(AddressData *selectedAddress)
            {
                if (selectedAddress != self.number.address)
                {
                    self.isLoading = YES;
                    [[WebClient sharedClient] updateNumberWithUuid:self.number.uuid
                                                              name:self.number.name
                                                         autoRenew:self.number.autoRenew
                                                   destinationUuid:nil
                                                       addressUuid:selectedAddress.uuid
                                                             reply:^(NSError*  error,
                                                                     NSString* e164,
                                                                     NSDate*   purchaseDate,
                                                                     NSDate*   expiryDate,
                                                                     float     monthFee,
                                                                     float     renewFee)
                    {
                        self.isLoading = NO;
                        if (error == nil)
                        {
                            self.number.address = selectedAddress;

                            // Check if the Number was purchased as a result of selecting a verified Address.
                            if (self.number.isPending && e164 != nil)
                            {
                                self.number.e164               = e164;
                                self.number.purchaseDate       = purchaseDate;
                                self.number.expiryDate         = expiryDate;
                                self.number.monthFee           = monthFee;
                                self.number.renewFee           = renewFee;
                                self.number.notifiedExpiryDays = INT16_MAX;
                            }

                            [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];
                            [self reloadAddressCell];

                            [[AppDelegate appDelegate] updateNumbersBadgeValue];
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
            chargesViewController       = [[IncomingChargesViewController alloc] initWithNumber:self.number];
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
    [[WebClient sharedClient] updateNumberWithUuid:self.number.uuid
                                              name:nil
                                         autoRenew:switchView.isOn
                                   destinationUuid:nil
                                       addressUuid:nil
                                             reply:^(NSError*  error,
                                                     NSString* e164,
                                                     NSDate*   purchaseDate,
                                                     NSDate*   expiryDate,
                                                     float     monthFee,
                                                     float     renewFee)
    {
        self.isLoading = NO;
        if (error == nil)
        {
            self.number.autoRenew = switchView.isOn;

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

                [switchView setOn:self.number.autoRenew animated:YES];
            }];
        }
    }];
}


- (void)deleteAction
{
    NSString* cantDeleteMessage = [self.number cantDeleteMessage];

    if (cantDeleteMessage == nil)
    {
        NSString* title       = NSLocalizedString(@"Delete this pending Number to receive back its price in Credit. "
                                                  @"Or, cancel if you want to resolve the Address issues.", @"");
        NSString* buttonTitle = NSLocalizedStringWithDefaultValue(@"NumberView DeleteTitle", nil, [NSBundle mainBundle],
                                                                  @"Delete Number",
                                                                  @"...\n"
                                                                  @"[1/3 line small font].");

        [BlockActionSheet showActionSheetWithTitle:title
                                        completion:^(BOOL cancelled, BOOL destruct, NSInteger buttonIndex)
        {
            if (destruct == YES)
            {
                isDeleting = YES;

                [self.number deleteWithCompletion:^(BOOL succeeded)
                {
                    if (succeeded)
                    {
                        [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];
                        [self.navigationController popViewControllerAnimated:YES];
                    }
                    else
                    {
                        isDeleting = NO;
                    }
                }];
            }
        }
                                 cancelButtonTitle:[Strings cancelString]
                            destructiveButtonTitle:buttonTitle
                                 otherButtonTitles:nil];
    }
    else
    {
        NSString* title;

        title = NSLocalizedStringWithDefaultValue(@"NumberView CantDeleteTitle", nil, [NSBundle mainBundle],
                                                  @"Can't Delete Number",
                                                  @"...\n"
                                                  @"[1/3 line small font].");

        [BlockAlertView showAlertViewWithTitle:title
                                       message:cantDeleteMessage
                                    completion:nil
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];
    }
}


#pragma mark - Cell Methods

- (void)updateInfoE164Cell:(UITableViewCell*)cell
{
    if (self.number.isPending)
    {
        cell.detailTextLabel.text      = [Strings pendingString];
        cell.detailTextLabel.textColor = [Skinning tintColor];

        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    else
    {
        NumberLabel*               numberLabel      = [Common addNumberLabelToCell:cell];
        PhoneNumber*               phoneNumber      = [[PhoneNumber alloc] initWithNumber:self.number.e164];
        NSString*                  string           = phoneNumber.internationalFormat;
        NSMutableAttributedString* attributedString = [[NSMutableAttributedString alloc] initWithString:string];

        UIFont*           font       = numberLabel.font;
        UIFontDescriptor* descriptor = [[font fontDescriptor] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
        UIFont*           boldFont   = [UIFont fontWithDescriptor:descriptor size:font.pointSize];

        NSRange range;
        if (self.number.areaCode.length > 0)
        {
            range = NSMakeRange(0, 1 + phoneNumber.callCountryCode.length + 1 + self.number.areaCode.length);
        }
        else
        {
            range = NSMakeRange(0, 1 + phoneNumber.callCountryCode.length);
        }

        [attributedString addAttribute:NSFontAttributeName value:boldFont range:range];
        
        numberLabel.attributedText = attributedString;

        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    NumberTypeMask numberTypeMask = [NumberType numberTypeMaskForString:self.number.numberType];

    cell.textLabel.text = [NumberType localizedStringForNumberTypeMask:numberTypeMask];
}


- (void)updateInfoAreaCell:(UITableViewCell*)cell
{
    cell.imageView.image      = [UIImage imageNamed:self.number.isoCountryCode];
    cell.detailTextLabel.text = [self areaName];
    cell.selectionStyle       = UITableViewCellSelectionStyleNone;
}


- (void)updateDestinationCell:(UITableViewCell*)cell
{
    if (self.number.destination == nil)
    {
        cell.detailTextLabel.text      = [Strings noneString];
        cell.detailTextLabel.textColor = [Skinning deleteTintColor];
    }
    else
    {
        cell.detailTextLabel.text      = [self.number.destination defaultName];
        cell.detailTextLabel.textColor = [Skinning valueColor];
    }

    cell.textLabel.text      = [Strings destinationString];
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
    if ([[Settings sharedSettings].callerIdE164 isEqualToString:self.number.e164])
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
            cell.detailTextLabel.text = [self.number purchaseDateString];
            cell.selectionStyle       = UITableViewCellSelectionStyleNone;
            break;
        }
        case 1:
        {
            cell.textLabel.text       = NSLocalizedStringWithDefaultValue(@"Number:PeriodRenewalDate Label", nil,
                                                                          [NSBundle mainBundle], @"Expiry",
                                                                          @"....");
            cell.detailTextLabel.text = [self.number expiryDateString];
            cell.selectionStyle       = UITableViewCellSelectionStyleNone;

            if ([self.number isExpiryCritical])
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

            NSString* monthPriceString = [[PurchaseManager sharedManager] localizedFormattedPrice:self.number.monthFee];
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
            switchView.on = self.number.autoRenew;
            break;
        }
    }
}


- (void)updateAddressCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    if (self.number.address != nil)
    {
        if ([AddressStatus isVerifiedAddressStatusMask:self.number.address.addressStatus])
        {
            cell.detailTextLabel.textColor = [Skinning valueColor];
        }
        else
        {
            cell.detailTextLabel.textColor = [Skinning deleteTintColor];
        }
    }
    else
    {
        if (self.number.isPending)
        {
            cell.detailTextLabel.textColor = [Skinning placeholderColor];
        }
        else
        {
            cell.detailTextLabel.textColor = [Skinning deleteTintColor];
        }
    }

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
    cell.detailTextLabel.text   = self.number.address ? self.number.address.name : [Strings requiredString];
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

    AddressTypeMask addressTypeMask = [AddressType addressTypeMaskForString:self.number.addressType];
    NumberTypeMask  numberTypeMask  = [NumberType numberTypeMaskForString:self.number.numberType];
    [AddressesViewController loadAddressesPredicateWithAddressType:addressTypeMask
                                                    isoCountryCode:self.number.isoCountryCode
                                                          areaCode:self.number.areaCode
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
    if (self.number.areaName.length > 0)
    {
        if (self.number.stateCode.length > 0)
        {
            return [NSString stringWithFormat:@"%@  %@", self.number.areaName, self.number.stateCode];
        }
        else
        {
            return self.number.areaName;
        }
    }
    else
    {
        return [[CountryNames sharedNames] nameForIsoCountryCode:self.number.isoCountryCode];
    }
}


#pragma mark - Baseclass Override

- (void)save
{
    if (self.number.changedValues.count == 0 || isDeleting == YES)
    {
        return;
    }

    self.isLoading = YES;
    [[WebClient sharedClient] updateNumberWithUuid:self.number.uuid
                                              name:self.number.name
                                         autoRenew:self.number.autoRenew
                                   destinationUuid:(self.number.destination == nil) ? @"" : self.number.destination.uuid
                                       addressUuid:nil  // When an Address is selected this call is already done above.
                                             reply:^(NSError*  error,
                                                     NSString* e164,
                                                     NSDate*   purchaseDate,
                                                     NSDate*   expiryDate,
                                                     float     monthFee,
                                                     float     renewFee)
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
                [self.number.managedObjectContext refreshObject:self.number mergeChanges:NO];
                [Common reloadSections:sections allSections:sections tableView:self.tableView];
            }];
        }
    }];
}

@end
