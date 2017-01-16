//
//  NumberAreaViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 11/03/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <objc/runtime.h>
#import "NumberAreaViewController.h"
#import "AddressesViewController.h"
#import "IncomingChargesViewController.h"
#import "NumberTermsViewController.h"
#import "NumberBuyViewController.h"
#import "Strings.h"
#import "WebClient.h"
#import "BlockAlertView.h"
#import "Common.h"
#import "CountryNames.h"
#import "NumberPayCell.h"
#import "Skinning.h"
#import "DataManager.h"
#import "AddressData.h"
#import "AddressStatus.h"
#import "Settings.h"
#import "PurchaseManager.h"


// Update reloadSections calls when adding/removing sections.
typedef enum
{
    TableSectionArea    = 1UL << 0, // Type, area code, area name, state, country.
    TableSectionName    = 1UL << 1, // Name given by user.
    TableSectionAddress = 1UL << 2,
    TableSectionCharges = 1UL << 3,
    TableSectionTerms   = 1UL << 4,
    TableSectionBuy     = 1UL << 5, // Buy.
} TableSections;

typedef enum
{
    AreaRowAreaCode = 1UL << 0,
    AreaRowAreaName = 1UL << 1,
    AreaRowState    = 1UL << 2,
    AreaRowCountry  = 1UL << 3,
} AreaRows;


@interface NumberAreaViewController () <UITextFieldDelegate, UIGestureRecognizerDelegate, UINavigationControllerDelegate>
{
    NSString*       numberIsoCountryCode;
    NSString*       areaCode;
    AddressTypeMask addressTypeMask;
    NSDictionary*   state;
    NSDictionary*   area;
    NumberTypeMask  numberTypeMask;

    BOOL            agreedToTerms;

    NSArray*        citiesArray;
    NSString*       name;
    BOOL            isChecked;
    TableSections   sections;
    AreaRows        areaRows;

    NSIndexPath*    actionIndexPath;
}

@property (nonatomic, strong) NSIndexPath*             nameIndexPath;

@property (nonatomic, strong) UIActivityIndicatorView* activityIndicator;
@property (nonatomic, assign) BOOL                     hasCorrectedInsets;
@property (nonatomic, strong) AddressData*             address;
@property (nonatomic, strong) NSPredicate*             addressesPredicate;
@property (nonatomic, assign) BOOL                     isLoadingAddress;
@property (nonatomic, assign) float                    setupFee;
@property (nonatomic, assign) float                    monthFee;
@property (nonatomic, strong) NSString*                areaName;

@end


@implementation NumberAreaViewController

- (instancetype)initWithIsoCountryCode:(NSString*)isoCountryCode
                                 state:(NSDictionary*)theState
                                  area:(NSDictionary*)theArea
                        numberTypeMask:(NumberTypeMask)theNumberTypeMask
{    
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        numberIsoCountryCode = isoCountryCode;
        state                = theState;
        area                 = theArea;
        areaCode             = [area[@"areaCode"] length] > 0 ? area[@"areaCode"] : nil;
        numberTypeMask       = theNumberTypeMask;
        addressTypeMask      = [AddressType addressTypeMaskForString:area[@"addressType"]];

        self.setupFee        = [area[@"setupFee"] floatValue];
        self.monthFee        = [area[@"monthFee"] floatValue];
        self.areaName        = (area[@"areaName"] != [NSNull null]) ? area[@"areaName"] : nil;

        // Mandatory sections.
        sections |= TableSectionArea;
        sections |= TableSectionName;
        sections |= TableSectionAddress;
        sections |= TableSectionTerms;
        sections |= TableSectionBuy;

        // Optional section.
        sections |= [IncomingChargesViewController hasIncomingChargesWithArea:area] ? TableSectionCharges : 0;

        // Always there Area section rows.
        areaRows |= AreaRowAreaCode;
        areaRows |= AreaRowCountry;
        
        // Conditionally there Area section rows.
        areaRows |= (numberTypeMask == NumberTypeGeographicMask) ? AreaRowAreaName : 0;
        areaRows |= (state != nil)                               ? AreaRowState    : 0;

        // Default naming.
        NSString* city;
        NSString* countryName = [[CountryNames sharedNames] nameForIsoCountryCode:numberIsoCountryCode];
        switch (numberTypeMask)
        {
            case NumberTypeGeographicMask:
            {
                city = [Common capitalizedString:area[@"city"]];
                name = [NSString stringWithFormat:@"%@ (%@)", city, numberIsoCountryCode];
                break;
            }
            case NumberTypeNationalMask:
            {
                name = [NSString stringWithFormat:@"%@ (nat)", countryName];
                break;
            }
            case NumberTypeMobileMask:
            {
                name = [NSString stringWithFormat:@"%@ (mob)", countryName];
                break;
            }
            case NumberTypeTollFreeMask:
            {
                name = [NSString stringWithFormat:@"%@ (free)", countryName];
                break;
            }
            case NumberTypeInternationalMask:
            {
                name = [NSString stringWithFormat:@"International (%@)", areaCode];
                break;
            }
        }
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedStringWithDefaultValue(@"NumberArea ScreenTitle", nil,
                                                                  [NSBundle mainBundle], @"Area",
                                                                  @"Title of app screen with one area.\n"
                                                                  @"[1 line larger font].");

    UIBarButtonItem* cancelButton;
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                 target:self
                                                                 action:@selector(cancelAction)];
    self.navigationItem.rightBarButtonItem = cancelButton;

    // Let keyboard be hidden when user taps outside text fields.
    UITapGestureRecognizer* gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                        action:@selector(hideKeyboard:)];
    gestureRecognizer.cancelsTouchesInView = NO;
    gestureRecognizer.delegate = self;
    [self.tableView addGestureRecognizer:gestureRecognizer];

    [self setupFootnotesHandlingOnTableView:self.tableView];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];

    [self loadAddressesPredicate];
}


#pragma mark - Helper Methods

- (void)hideKeyboard:(UIGestureRecognizer*)gestureRecognizer
{
    if (name.length > 0)
    {
        if (self.hasCorrectedInsets == YES)
        {
            //### Workaround: http://stackoverflow.com/a/22053349/1971013
            [self.tableView setContentInset:UIEdgeInsetsMake(64, 0, 265, 0)];
            [self.tableView setScrollIndicatorInsets:UIEdgeInsetsMake(64, 0, 265, 0)];
            
            self.hasCorrectedInsets = NO;
        }
        
        [[self.tableView superview] endEditing:YES];
    }
}


- (void)cancelAction
{
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];

    [AddressesViewController cancelLoadingAddressPredicate];
}


- (void)loadAddressesPredicate
{
    if (self.address == nil)
    {
        self.isLoadingAddress = YES;
        [self reloadAddressCell];
    }

    [AddressesViewController loadAddressesPredicateWithAddressType:addressTypeMask
                                                    isoCountryCode:numberIsoCountryCode
                                                          areaCode:areaCode
                                                        numberType:numberTypeMask
                                                      areAvailable:NO
                                                        completion:^(NSPredicate *predicate, NSError *error)
    {
        self.isLoadingAddress = NO;
        if (error == nil)
        {
            [self reloadAddressCell];
            self.addressesPredicate = predicate;
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
                                                @"Loading the list of valid addresses for this area failed: %@\n\n"
                                                @"Please try again later.",
                                                @"Alert message telling that loading areas over internet failed.\n"
                                                @"[iOS alert message size!]");
    message = [NSString stringWithFormat:message, error.localizedDescription];
    [BlockAlertView showAlertViewWithTitle:title
                                   message:message
                                completion:^(BOOL cancelled, NSInteger buttonIndex)
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
                         cancelButtonTitle:[Strings cancelString]
                         otherButtonTitles:nil];
}


#pragma mark - Buy Cell Delegate

- (BOOL)canBuy
{
    NSString* title = nil;
    NSString* message;

    if (name.length == 0)
    {
        title   = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                    @"Name Is Missing",
                                                    @"....\n"
                                                    @"[iOS alert title size].");
        message = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                    @"Please enter a short descriptive name for this Number.",
                                                    @"....\n"
                                                    @"[iOS alert message size]");
    }
    else if (self.address == nil)
    {
        title   = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                    @"Address Is Missing",
                                                    @"....\n"
                                                    @"[iOS alert title size].");
        message = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                    @"Please add your address or select an address you added earlier.",
                                                    @"....\n"
                                                    @"[iOS alert message size]");
    }
    else if (agreedToTerms == NO)
    {
        title   = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                    @"Not Agreed To Terms",
                                                    @"....\n"
                                                    @"[iOS alert title size].");
        message = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                    @"Please explicitly agree to each of the terms for using a Number.",
                                                    @"....\n"
                                                    @"[iOS alert message size]");
    }
    else
    {
        switch (self.address.addressStatus)
        {
            case AddressStatusUnknown:
            {
                title   = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                            @"Unknown Address Status",
                                                            @"....\n"
                                                            @"[iOS alert title size].");
                message = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                            @"Your address needs to be verified, "
                                                            @"but it's state is unknown at the moment.",
                                                            @"....\n"
                                                            @"[iOS alert message size]");
                break;
            }
            case AddressStatusStagedMask:
            {
                break;
            }
            case AddressStatusNotVerifiedMask:
            {
                break;
            }
            case AddressStatusDisabledMask:
            {
                // Don't know when this occurs, it at all.
                title   = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                            @"Address Disabled",
                                                            @"....\n"
                                                            @"[iOS alert title size].");
                message = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                            @"Your address has been disabled.",
                                                            @"....\n"
                                                            @"[iOS alert message size]");
                break;
            }
            case AddressStatusVerifiedMask:
            {
                break;
            }
            case AddressStatusVerificationRequestedMask:
            {
                title   = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                            @"Address Waiting Verification",
                                                            @"....\n"
                                                            @"[iOS alert title size].");
                message = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                            @"Your address is waiting to be verified.",
                                                            @"....\n"
                                                            @"[iOS alert message size]");
                break;
            }
            case AddressStatusRejectedMask:
            {
                title   = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                            @"Address Rejected",
                                                            @"....\n"
                                                            @"[iOS alert title size].");
                message = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                            @"Your address has been rejected.",
                                                            @"....\n"
                                                            @"[iOS alert message size]");
                break;
            }
        }
    }

    if (title != nil)
    {
        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:nil
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];
        return NO;
    }
    else
    {
        return YES;
    }
}


#pragma mark - Table View Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return [Common bitsSetCount:sections];
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* title = nil;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionArea:
        {
            title = NSLocalizedStringWithDefaultValue(@"NumberArea:Area SectionHeader", nil, [NSBundle mainBundle],
                                                      @"Current Selection",
                                                      @"...");
            break;
        }
        case TableSectionName:
        {
            title = NSLocalizedStringWithDefaultValue(@"NumberArea:Naming SectionHeader", nil, [NSBundle mainBundle],
                                                      @"Number's Name In App",
                                                      @"...");
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
        case TableSectionArea:
        {
            break;
        }
        case TableSectionName:
        {
            title = [Strings nameFooterString];
            break;
        }
        case TableSectionAddress:
        {
            title = NSLocalizedStringWithDefaultValue(@"NumberArea:Address SectionFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"A contact name and address "
                                                      @"are legally required.",
                                                      @"Explaining that information must be supplied by user.");
            break;
        }
        case TableSectionCharges:
        {
            title = NSLocalizedStringWithDefaultValue(@"NumberArea:Charges SectionFooter", nil, [NSBundle mainBundle],
                                                      @"When someone calls you at this Number, additional "
                                                      @"charges apply.",
                                                      @"....");
            break;
        }
    }

    return title;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionArea:    numberOfRows = [Common bitsSetCount:areaRows]; break;
        case TableSectionName:    numberOfRows = 1;                              break;
        case TableSectionAddress: numberOfRows = 1;                              break;
        case TableSectionCharges: numberOfRows = 1;                              break;
        case TableSectionTerms:   numberOfRows = 1;                              break;
        case TableSectionBuy:     numberOfRows = 1;                              break;
    }

    return numberOfRows;
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];

    if (cell.selectionStyle == UITableViewCellSelectionStyleNone)
    {
        return;
    }

    switch ([Common nthBitSet:indexPath.section inValue:sections])
    {
        case TableSectionAddress:
        {
            NSManagedObjectContext*  managedObjectContext = [DataManager sharedManager].managedObjectContext;
            AddressesViewController* viewController;

            viewController = [[AddressesViewController alloc] initWithManagedObjectContext:managedObjectContext
                                                                           selectedAddress:self.address
                                                                            isoCountryCode:numberIsoCountryCode
                                                                                  areaCode:areaCode
                                                                                    areaId:area[@"areaId"]
                                                                                      city:area[@"city"]
                                                                                numberType:numberTypeMask
                                                                               addressType:addressTypeMask
                                                                                 predicate:self.addressesPredicate
                                                                                isVerified:NO
                                                                                completion:^(AddressData *selectedAddress)
            {
                self.address = selectedAddress;
                [self reloadAddressCell];
            }];

            [self.navigationController pushViewController:viewController animated:YES];
            break;
        }
        case TableSectionTerms:
        {
            NumberTermsViewController* viewController;
            viewController = [[NumberTermsViewController alloc] initWithAgreed:agreedToTerms agreedCompletion:^
            {
                agreedToTerms = YES;

                UITableViewCell* cell     = [self.tableView cellForRowAtIndexPath:indexPath];
                cell.detailTextLabel.text = nil;
                cell.accessoryType        = UITableViewCellAccessoryCheckmark;
            }];

            viewController.title = cell.textLabel.text;
            [self.navigationController pushViewController:viewController animated:YES];
            break;
        }
        case TableSectionCharges:
        {
            IncomingChargesViewController* chargesViewController;

            chargesViewController       = [[IncomingChargesViewController alloc] initWithArea:area];
            chargesViewController.title = cell.textLabel.text;
            [self.navigationController pushViewController:chargesViewController animated:YES];
            break;
        }
        case TableSectionBuy:
        {
            if ([self canBuy])
            {
                NumberBuyViewController* payViewController;

                payViewController = [[NumberBuyViewController alloc] initWithMonthFee:self.monthFee
                                                                             setupFee:self.setupFee
                                                                                 name:name
                                                                       numberTypeMask:numberTypeMask
                                                                       isoCountryCode:numberIsoCountryCode
                                                                                state:state
                                                                                 area:area
                                                                             areaCode:areaCode
                                                                             areaName:self.areaName
                                                                              areadId:area[@"areaId"]
                                                                              address:self.address];
                payViewController.title = cell.textLabel.text;
                [self.navigationController pushViewController:payViewController animated:YES];
            }
            else
            {
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            }
            break;
        }
    }
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    switch ([Common nthBitSet:indexPath.section inValue:sections])
    {
        case TableSectionArea:    cell = [self areaCellForRowAtIndexPath:indexPath];    break;
        case TableSectionName:    cell = [self nameCellForRowAtIndexPath:indexPath];    break;
        case TableSectionAddress: cell = [self addressCellForRowAtIndexPath:indexPath]; break;
        case TableSectionCharges: cell = [self chargesCellForRowAtIndexPath:indexPath]; break;
        case TableSectionTerms:   cell = [self termsCellForRowAtIndexPath:indexPath];   break;
        case TableSectionBuy:     cell = [self buyCellForRowAtIndexPath:indexPath];     break;
    }

    return cell;
}


#pragma mark - Cell Methods

- (UITableViewCell*)areaCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    NSString*        identifier;

    identifier  = ([Common nthBitSet:indexPath.row inValue:areaRows] == AreaRowCountry) ? @"CountryCell"
                                                                                        : @"Value1Cell";
    cell        = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    }

    switch ([Common nthBitSet:indexPath.row inValue:areaRows])
    {
        case AreaRowAreaCode:
        {
            cell.textLabel.text       = [NumberType localizedStringForNumberTypeMask:numberTypeMask];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"+%@ %@",
                                                                   [Common callingCodeForCountry:numberIsoCountryCode],
                                                                   areaCode ? areaCode : @"---"];
            cell.imageView.image      = nil;
            break;
        }
        case AreaRowAreaName:
        {
            cell.textLabel.text       = [Strings areaString];
            cell.detailTextLabel.text = [Common capitalizedString:self.areaName];
            cell.imageView.image      = nil;
            break;
        }
        case AreaRowState:
        {
            cell.textLabel.text       = [Strings stateString];
            cell.detailTextLabel.text = state[@"stateName"];
            cell.imageView.image      = nil;
            break;
        }
        case AreaRowCountry:
        {
            cell.textLabel.text       = @" ";     // Without this, the detailTextLabel is on the left.
            cell.detailTextLabel.text = [[CountryNames sharedNames] nameForIsoCountryCode:numberIsoCountryCode];
            [Common addCountryImageToCell:cell isoCountryCode:numberIsoCountryCode];
            break;
        }
    }

    cell.accessoryType  = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}


- (UITableViewCell*)nameCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    UITextField*     textField;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"TextFieldCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"TextFieldCell"];
        textField = [Common addTextFieldToCell:cell delegate:self];
        textField.tag = CommonTextFieldCellTag;
    }
    else
    {
        textField = (UITextField*)[cell viewWithTag:CommonTextFieldCellTag];
    }

    cell.textLabel.text              = [Strings nameString];
    textField.placeholder            = [Strings requiredString];
    textField.text                   = [name stringByReplacingOccurrencesOfString:@" " withString:@"\u00a0"];
    textField.userInteractionEnabled = YES;
    objc_setAssociatedObject(textField, @"TextFieldKey", @"name", OBJC_ASSOCIATION_RETAIN);

    cell.detailTextLabel.text = nil;
    cell.imageView.image      = nil;
    cell.accessoryType        = UITableViewCellAccessoryNone;
    cell.selectionStyle       = UITableViewCellSelectionStyleNone;

    [self updateTextField:textField onCell:cell];

    return cell;
}


- (UITableViewCell*)addressCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"AddressCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"AddressCell"];
    }
    
    cell.textLabel.text            = [Strings addressString];
    cell.detailTextLabel.textColor = self.address ? [Skinning valueColor] : [Skinning placeholderColor];
    cell.accessoryType             = UITableViewCellAccessoryDisclosureIndicator;

    if (self.isLoadingAddress)
    {
        UIActivityIndicatorView* spinner;
        spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [spinner startAnimating];

        cell.accessoryView          = spinner;
        cell.userInteractionEnabled = NO;
        cell.detailTextLabel.text   = nil;
    }
    else
    {
        cell.accessoryView          = nil;
        cell.userInteractionEnabled = YES;
        cell.detailTextLabel.text   = self.address ? self.address.name : [Strings requiredString];
    }

    return cell;
}


- (UITableViewCell*)chargesCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"ChargesCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"ChargesCell"];
    }

    cell.accessoryType        = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text       = [Strings incomingChargesString];
    cell.detailTextLabel.text = @"";

    return cell;
}


- (UITableViewCell*)termsCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"TermsCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"TermsCell"];
    }

    cell.textLabel.text            = @"Agree To Terms";
    cell.detailTextLabel.textColor = [Skinning placeholderColor];

    if (agreedToTerms)
    {
        cell.detailTextLabel.text = nil;
        cell.accessoryType        = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        cell.accessoryType        = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.text = [Strings requiredString];
    }

    return cell;
}


- (UITableViewCell*)buyCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"BuyCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"BuyCell"];
    }

    cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"NumberArea BuyTitle", nil, [NSBundle mainBundle],
                                                            @"Select Period",
                                                            @"....\n"
                                                            @"[1 line larger font].");

    float     monthPrice       = [area[@"monthFee"] floatValue];
    NSString* monthPriceString = [[PurchaseManager sharedManager] localizedFormattedPrice:monthPrice];
    cell.detailTextLabel.text      = [NSString stringWithFormat:@"%@/%@", monthPriceString, [Strings monthString]];
    cell.detailTextLabel.textColor = [Skinning priceColor];

    cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}


- (void)updateTextField:(UITextField*)textField onCell:(UITableViewCell*)cell
{
    cell.detailTextLabel.text = nil;
    cell.imageView.image      = nil;

    if (cell.accessoryType == UITableViewCellAccessoryDisclosureIndicator)
    {
        [Common setX:60 ofView:textField];
        textField.textColor = [UIColor grayColor];
    }
    else
    {
        [Common setX:80 ofView:textField];
        if (textField.userInteractionEnabled == YES)
        {
            textField.textColor = [Skinning tintColor];
        }
        else
        {
            textField.textColor = [UIColor grayColor];
        }
    }
}


#pragma mark - TextField Delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField*)textField
{
    //#### Copy-paste from ItemViewController, see if superclass can be used.
    textField.returnKeyType                 = UIReturnKeyDone;
    textField.enablesReturnKeyAutomatically = YES;
    
    #warning The method reloadInputViews messes up two-byte keyboards (e.g. Kanji).
    [textField reloadInputViews];
    
    //### Workaround: http://stackoverflow.com/a/22053349/1971013
    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC));
    dispatch_after(when, dispatch_get_main_queue(), ^(void)
    {
        if (self.tableView.contentInset.bottom == 265)
        {
            [self.tableView setContentInset:UIEdgeInsetsMake(64, 0, 216, 0)];
            [self.tableView setScrollIndicatorInsets:UIEdgeInsetsMake(64, 0, 216, 0)];
            
            self.hasCorrectedInsets = YES;
        }
    });
    
    return YES;
}


- (NSIndexPath*)findCellIndexPathForSubview:(UIView*)subview
{
    UIView* superview = subview.superview;
    while ([superview class] != [UITableViewCell class])
    {
        superview = superview.superview;
    }

    return [self.tableView indexPathForCell:(UITableViewCell*)superview];
}


// Not used at the moment, because there are no clear buttons.
- (BOOL)textFieldShouldClear:(UITextField*)textField
{
    NSString* key = objc_getAssociatedObject(textField, @"TextFieldKey");
    
    if ([key isEqualToString:@"name"])
    {
        name = @"";
    }
    
    return YES;
}


- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    [textField resignFirstResponder];
    
    if (self.hasCorrectedInsets == YES)
    {
        //### Workaround: http://stackoverflow.com/a/22053349/1971013
        [self.tableView setContentInset:UIEdgeInsetsMake(64, 0, 265, 0)];
        [self.tableView setScrollIndicatorInsets:UIEdgeInsetsMake(64, 0, 265, 0)];
        
        self.hasCorrectedInsets = NO;
    }
    
    // we can always return YES, because the Done button will be disabled when there's no text.
    return YES;
}


- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string
{
    // See http://stackoverflow.com/a/14792880/1971013 for keeping cursor on correct position.
    UITextPosition* beginning    = textField.beginningOfDocument;
    UITextPosition* start        = [textField positionFromPosition:beginning offset:range.location];
    NSInteger       cursorOffset = [textField offsetFromPosition:beginning toPosition:start] + string.length;
    
    // See http://stackoverflow.com/a/22211018/1971013 why we're using non-breaking spaces @"\u00a0".
    textField.text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    textField.text = [textField.text stringByReplacingOccurrencesOfString:@" " withString:@"\u00a0"];
    
    name = [textField.text stringByReplacingOccurrencesOfString:@"\u00a0" withString:@" "];
    
    [self.tableView scrollToRowAtIndexPath:self.nameIndexPath
                          atScrollPosition:UITableViewScrollPositionNone
                                  animated:YES];
    
    // See http://stackoverflow.com/a/14792880/1971013 for keeping cursor on correct position.
    UITextPosition* newCursorPosition = [textField positionFromPosition:textField.beginningOfDocument offset:cursorOffset];
    UITextRange*    newSelectedRange  = [textField textRangeFromPosition:newCursorPosition toPosition:newCursorPosition];
    [textField setSelectedTextRange:newSelectedRange];
    
    return NO;  // Need to return NO, because we've already changed textField.text.
}


#pragma mark - Gesture Recognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldReceiveTouch:(UITouch*)touch
{
    if ([touch.view isKindOfClass:[UITextField class]] || [touch.view isKindOfClass:[UIButton class]])
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

@end
