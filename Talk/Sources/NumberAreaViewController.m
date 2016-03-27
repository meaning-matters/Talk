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
#import "Strings.h"
#import "WebClient.h"
#import "BlockAlertView.h"
#import "Common.h"
#import "CountryNames.h"
#import "NumberBuyCell.h"
#import "PurchaseManager.h"
#import "Skinning.h"
#import "DataManager.h"
#import "AddressData.h"
#import "AddressStatus.h"


// Update reloadSections calls when adding/removing sections.
typedef enum
{
    TableSectionArea    = 1UL << 0, // Type, area code, area name, state, country.
    TableSectionName    = 1UL << 1, // Name given by user.
    TableSectionAddress = 1UL << 2,
    TableSectionBuy     = 1UL << 3, // Buy.
} TableSections;

typedef enum
{
    AreaRowType     = 1UL << 0,
    AreaRowAreaCode = 1UL << 1,
    AreaRowAreaName = 1UL << 2,
    AreaRowState    = 1UL << 3,
    AreaRowCountry  = 1UL << 4,
} AreaRows;


@interface NumberAreaViewController () <UITextFieldDelegate, UIGestureRecognizerDelegate, UINavigationControllerDelegate,
                                        NumberBuyCellDelegate>
{
    NSString*       numberIsoCountryCode;
    NSString*       areaCode;
    AddressTypeMask addressTypeMask;
    NSDictionary*   state;
    NSDictionary*   area;
    NumberTypeMask  numberTypeMask;


    NSArray*       citiesArray;
    NSString*      name;
    BOOL           isChecked;
    TableSections  sections;
    AreaRows       areaRows;

    NSIndexPath*   actionIndexPath;
}

@property (nonatomic, strong) NSIndexPath*             nameIndexPath;

@property (nonatomic, strong) UIActivityIndicatorView* activityIndicator;
@property (nonatomic, assign) BOOL                     hasCorrectedInsets;
@property (nonatomic, strong) AddressData*             address;
@property (nonatomic, strong) NSPredicate*             addressesPredicate;
@property (nonatomic, assign) BOOL                     isLoadingAddress;
@property (nonatomic, assign) CGFloat                  buyCellHeight;
@property (nonatomic, strong) NumberBuyCell*           buyCell;
@property (nonatomic, assign) BOOL                     isBuying;
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
        self.areaName        = area[@"areaName"];

        // Mandatory sections.
        sections |= TableSectionArea;
        sections |= TableSectionName;
        sections |= TableSectionAddress;
        sections |= TableSectionBuy;

        // Always there Area section rows.
        areaRows |= AreaRowType;
        areaRows |= AreaRowCountry;
        
        // Conditionally there Area section rows.
        BOOL allCities = (area[@"areaName"] != [NSNull null] &&
                          [self.areaName caseInsensitiveCompare:@"all cities"] == NSOrderedSame);
        areaRows |= (areaCode != nil)                                          ? AreaRowAreaCode : 0;
        areaRows |= (numberTypeMask == NumberTypeGeographicMask && !allCities) ? AreaRowAreaName : 0;
        areaRows |= (numberTypeMask == NumberTypeSpecialMask)                  ? AreaRowAreaName : 0;
        areaRows |= (state != nil)                                             ? AreaRowState    : 0;

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
                name = [NSString stringWithFormat:@"%@ (paid)", countryName];
                break;
            }
            case NumberTypeMobileMask:
            {
                name = [NSString stringWithFormat:@"%@ (mobile)", countryName];
                break;
            }
            case NumberTypeTollFreeMask:
            {
                name = [NSString stringWithFormat:@"%@ (free)", countryName];
                break;
            }
            case NumberTypeSharedCostMask:
            {
                name = [NSString stringWithFormat:@"%@ (shared)", countryName];
                break;
            }
            case NumberTypeSpecialMask:
            {
                name = [NSString stringWithFormat:@"%@ (special)", countryName];
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

    [self.tableView registerNib:[UINib nibWithNibName:@"NumberBuyCell" bundle:nil]
         forCellReuseIdentifier:@"NumberBuyCell"];

    UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"NumberBuyCell"];
    self.buyCellHeight    = cell.bounds.size.height;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];

    [self loadAddressesPredicate];
}


#pragma mark - Helper Methods

- (BOOL)isAddressRequired
{
    return (addressTypeMask != AddressTypeNoneMask);
}


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
        
        //####[self save];
        [[self.tableView superview] endEditing:YES];
    }
}


- (void)cancelAction
{
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
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
                                                @"Alert title telling that loading countries over internet failed.\n"
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


- (void)updateBuyCell
{
    NSString* monthTitle = NSLocalizedStringWithDefaultValue(@"NumberArea LoadFailAlertMessage", nil, [NSBundle mainBundle],
                                                             @"%@ monthly fee",
                                                             @"£2.34 monthly fee");
    NSString* setupTitle;

    monthTitle = [NSString stringWithFormat:monthTitle, [self stringForFee:self.monthFee]];
    if (self.setupFee > 0.0f)
    {
        setupTitle = NSLocalizedStringWithDefaultValue(@"NumberArea LoadFailAlertMessage", nil, [NSBundle mainBundle],
                                                       @"%@ setup fee",
                                                       @"£2.34 setup fee");
        setupTitle = [NSString stringWithFormat:setupTitle, [self stringForFee:self.setupFee]];
    }
    else
    {
        setupTitle = NSLocalizedStringWithDefaultValue(@"NumberArea LoadFailAlertMessage", nil, [NSBundle mainBundle],
                                                       @"(no setup fee)",
                                                       @"");
    }

    NSString* title = [NSString stringWithFormat:@"%@\n%@", monthTitle, setupTitle];
    [self.buyCell.button setTitle:title forState:UIControlStateNormal];
    [Common styleButton:self.buyCell.button];

    self.buyCell.button.alpha                  = (self.isBuying != 0) ? 0.5 : 1.0;
    self.buyCell.button.userInteractionEnabled = (self.isBuying == 0);
    self.isBuying ? [self.buyCell.activityIndicator startAnimating] : [self.buyCell.activityIndicator stopAnimating];
}


- (NSString*)stringForFee:(float)fee
{
    return [[PurchaseManager sharedManager] localizedFormattedPrice:fee];
}


#pragma mark - Buy Cell Delegate

- (void)buyNumberAction
{
    NSString* title;
    NSString* message;

    if ([self canBuy] == YES)
    {
        title   = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                    @"Buy Number",
                                                    @"....\n"
                                                    @"[iOS alert title size].");
        if (self.setupFee > 0.0f)
        {
            message = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                        @"Yes, buy this Number for %@ per month, "
                                                        @"plus a one-time setup fee of %@.\n\n",
                                                        @"....\n"
                                                        @"[iOS alert message size]");
            message = [NSString stringWithFormat:message, [self stringForFee:self.monthFee],
                                                          [self stringForFee:self.setupFee]];
        }
        else
        {
            message = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                        @"Yes, buy this Number for %@ per month "
                                                        @"(without one-time setup fee).\n\n",
                                                        @"....\n"
                                                        @"[iOS alert message size]");
            message = [NSString stringWithFormat:message, [self stringForFee:self.monthFee]];
        }

        NSString* monthlyMessage = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                                     @"%@The monthly fee is taking from your Credit "
                                                                     @"until you cancel.",
                                                                     @"....\n"
                                                                     @"[iOS alert message size]");
        message = [NSString stringWithFormat:monthlyMessage, message];
        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
        {
            if (buttonIndex == 1)
            {
                [self buyNumber];
            }
        }
                             cancelButtonTitle:[Strings cancelString]
                             otherButtonTitles:[Strings buyString], nil];
    }
}


- (void)buyNumber
{
    self.isBuying = YES;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [self updateBuyCell];
    void (^buyNumberBlock)(void) = ^
    {
        [[WebClient sharedClient] purchaseNumberForMonths:1
                                                     name:self->name
                                           isoCountryCode:numberIsoCountryCode
                                                   areaId:self->area[@"areaId"]
                                                addressId:self.address.addressId
                                                    reply:^(NSError* error, NSString *e164)
        {
            if (error == nil)
            {
                [[AppDelegate appDelegate].numbersViewController refresh:nil];
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            else
            {
                NSString* title;
                NSString* message;

                title   = NSLocalizedStringWithDefaultValue(@"BuyNumber FailedBuyNumberTitle", nil,
                                                            [NSBundle mainBundle], @"Buying Number Failed",
                                                            @"Alert title: A phone number could not be bought.\n"
                                                            @"[iOS alert title size].");
                message = NSLocalizedStringWithDefaultValue(@"BuyNumber FailedBuyNumberMessage", nil,
                                                            [NSBundle mainBundle],
                                                            @"Something went wrong while buying your number: %@\n\n"
                                                            @"Please try again later.",
                                                            @"Message telling that buying a phone number failed\n"
                                                            @"[iOS alert message size]");
                message = [NSString stringWithFormat:message, [error localizedDescription]];
                [BlockAlertView showAlertViewWithTitle:title
                                               message:message
                                            completion:^(BOOL cancelled, NSInteger buttonIndex)
                {
                    [self dismissViewControllerAnimated:YES completion:nil];
                }
                                     cancelButtonTitle:[Strings closeString]
                                     otherButtonTitles:nil];
            }
        }];
    };

    // Check if there's enough credit.
    [[WebClient sharedClient] retrieveCreditWithReply:^(NSError* error, float credit)
    {
        float totalFee = self.setupFee + self.monthFee;
        if (error == nil)
        {
            if (totalFee < credit)
            {
                buyNumberBlock();
            }
            else
            {
                int extraCreditAmount = [[PurchaseManager sharedManager] amountForCredit:totalFee - credit];
                if (extraCreditAmount > 0)
                {
                    NSString* productIdentifier;
                    NSString* extraString;
                    NSString* creditString;
                    NSString* title;
                    NSString* message;

                    productIdentifier = [[PurchaseManager sharedManager] productIdentifierForCreditAmount:extraCreditAmount];
                    extraString       = [[PurchaseManager sharedManager] localizedPriceForProductIdentifier:productIdentifier];
                    creditString      = [[PurchaseManager sharedManager] localizedFormattedPrice:credit];

                    title   = NSLocalizedStringWithDefaultValue(@"BuyNumber NeedExtraCreditTitle", nil,
                                                                [NSBundle mainBundle], @"Extra Credit Needed",
                                                                @"Alert title: extra credit must be bought.\n"
                                                                @"[iOS alert title size].");
                    message = NSLocalizedStringWithDefaultValue(@"BuyNumber NeedExtraCreditMessage", nil,
                                                                [NSBundle mainBundle],
                                                                @"The price is more than your current "
                                                                @"credit: %@.\n\nYou can buy %@ extra credit now.",
                                                                @"Alert message: buying extra credit id needed.\n"
                                                                @"[iOS alert message size]");
                    message = [NSString stringWithFormat:message, creditString, extraString];
                    [BlockAlertView showAlertViewWithTitle:title
                                                   message:message
                                                completion:^(BOOL cancelled, NSInteger buttonIndex)
                    {
                        if (cancelled == NO)
                        {
                            [[PurchaseManager sharedManager] buyCreditAmount:extraCreditAmount
                                                                  completion:^(BOOL success, id object)
                            {
                                if (success == YES)
                                {
                                    buyNumberBlock();
                                }
                                else if (object != nil && ((NSError*)object).code == SKErrorPaymentCancelled)
                                {
                                    [self dismissViewControllerAnimated:YES completion:nil];
                                }
                                else if (object != nil)
                                {
                                    NSString* title;
                                    NSString* message;

                                    title   = NSLocalizedStringWithDefaultValue(@"BuyNumber FailedBuyCreditTitle", nil,
                                                                                [NSBundle mainBundle], @"Buying Credit Failed",
                                                                                @"Alert title: Credit could not be bought.\n"
                                                                                @"[iOS alert title size].");
                                    message = NSLocalizedStringWithDefaultValue(@"BuyNumber FailedBuyCreditMessage", nil,
                                                                                [NSBundle mainBundle],
                                                                                @"Something went wrong while buying credit: "
                                                                                @"%@\n\nPlease try again later.",
                                                                                @"Message telling that buying credit failed\n"
                                                                                @"[iOS alert message size]");
                                    message = [NSString stringWithFormat:message, [object localizedDescription]];
                                    [BlockAlertView showAlertViewWithTitle:title
                                                                   message:message
                                                                completion:^(BOOL cancelled, NSInteger buttonIndex)
                                    {
                                        [self dismissViewControllerAnimated:YES completion:nil];
                                    }
                                                         cancelButtonTitle:[Strings closeString]
                                                         otherButtonTitles:nil];
                                }
                            }];
                        }
                        else
                        {
                            self.isBuying = NO;
                            self.navigationItem.rightBarButtonItem.enabled = YES;
                            [self updateBuyCell];
                        }
                    }
                                         cancelButtonTitle:[Strings cancelString]
                                         otherButtonTitles:[Strings buyString], nil];
                }
                else
                {
                    NBLog(@"//### Apparently there's no sufficiently high credit product.");
                }
            }
        }
        else
        {
            NSString* title;
            NSString* message;

            title   = NSLocalizedStringWithDefaultValue(@"BuyNumber FailedGetCreditTitle", nil,
                                                        [NSBundle mainBundle], @"Credit Unknown",
                                                        @"Alert title: Reading the user's credit failed.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"BuyNumber FailedGetCreditMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Could not get your up-to-date credit, from our "
                                                        @"internet server. (Credit is needed for the "
                                                        @"setup fee.)\n\nPlease try again later.",
                                                        @"Message telling that buying a phone number failed\n"
                                                        @"[iOS alert message size]");
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
            {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
                                 cancelButtonTitle:[Strings closeString]
                                 otherButtonTitles:nil];
        }
    }];
}


- (BOOL)canBuy
{
    NSString* title = nil;
    NSString* message;

    if (name.length == 0 || (addressTypeMask != AddressTypeNoneMask && self.address == nil))
    {
        title   = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                    @"Information Missing",
                                                    @"....\n"
                                                    @"[iOS alert title size].");
        message = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                    @"Please complete the information for all required fields.",
                                                    @"....\n"
                                                    @"[iOS alert message size]");
    }
    else if (addressTypeMask != AddressTypeNoneMask)
    {
        if (area[@"proofTypes"] == nil)
        {
            // No proof is required.
            if (self.address.addressStatus != AddressStatusNotVerifiedMask)
            {
                title   = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                            @"Unexpected Address Status",
                                                            @"....\n"
                                                            @"[iOS alert title size].");
                message = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                            @"The selected address has an unexpected status.",
                                                            @"....\n"
                                                            @"[iOS alert message size]");
            }
        }
        else
        {
            // Proof is required, which much be verified.
            switch (self.address.addressStatus)
            {
                case AddressStatusUnknown:
                {
                    title   = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                                @"Unknown Address Status",
                                                                @"....\n"
                                                                @"[iOS alert title size].");
                    message = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                                @"Your proof of address image needs to be verified, "
                                                                @"but it's state is unknown at the moment.",
                                                                @"....\n"
                                                                @"[iOS alert message size]");
                    break;
                }
                case AddressStatusNotVerifiedMask:
                {
                    // This can't occur, if we understand Voxbone correctly.
                    title   = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                                @"Address Not Verified",
                                                                @"....\n"
                                                                @"[iOS alert title size].");
                    message = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                                @"Your proof of address image has not been verified.",
                                                                @"....\n"
                                                                @"[iOS alert message size]");
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
                                                                @"Your proof of address image is waiting to be verified.",
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
                                                                @"Your proof of address image has been rejected.",
                                                                @"....\n"
                                                                @"[iOS alert message size]");
                    break;
                }
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
    NSString*   title = nil;

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
        case TableSectionBuy:
        {
            title = NSLocalizedStringWithDefaultValue(@"NumberArea:Buy SectionHeader", nil, [NSBundle mainBundle],
                                                      @"Buy Number In This Area",
                                                      @"...");
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
            if ([self isAddressRequired])
            {
                title = NSLocalizedStringWithDefaultValue(@"NumberArea:Address SectionFooter", nil,
                                                          [NSBundle mainBundle],
                                                          @"A contact name and address "
                                                          @"are legally required.",
                                                          @"Explaining that information must be supplied by user.");
            }
            else
            {
                title = NSLocalizedStringWithDefaultValue(@"NumberArea:Address SectionFooter", nil,
                                                          [NSBundle mainBundle],
                                                          @"A contact name and address "
                                                          @"are optional, and could be asked later.",
                                                          @"Explaining that information must be supplied by user.");
            }
            break;
        }
        case TableSectionBuy:
        {
            if (self.setupFee == 0.0f)
            {
                title = NSLocalizedStringWithDefaultValue(@"NumberArea:... NoSetupFeeTableFooter", nil, [NSBundle mainBundle],
                                                          @"The fee will be taken from your Credit. If your Credit "
                                                          @"is too low, you'll be warned and asked to buy more.",
                                                          @"[Multiple lines]");
            }
            else
            {
                title = NSLocalizedStringWithDefaultValue(@"NumberArea:... TableFooter", nil, [NSBundle mainBundle],
                                                          @"The fee(s) will be taken from your Credit. If your Credit "
                                                          @"is too low, you'll be warned and asked to buy more.",
                                                          @"[Multiple lines]");
                
                title = [NSString stringWithFormat:title, [self stringForFee:self.setupFee]];
            }
            
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
        case TableSectionArea:
        {
            numberOfRows = [Common bitsSetCount:areaRows];
            break;
        }
        case TableSectionName:
        {
            numberOfRows = 1;
            break;
        }
        case TableSectionAddress:
        {
            numberOfRows = 1;
            break;
        }
        case TableSectionBuy:
        {
            numberOfRows = 1;
            break;
        }
    }

    return numberOfRows;
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    if ([self.tableView cellForRowAtIndexPath:indexPath].selectionStyle == UITableViewCellSelectionStyleNone)
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
                                                                                numberType:numberTypeMask
                                                                               addressType:addressTypeMask
                                                                                proofTypes:area[@"proofTypes"]
                                                                                 predicate:self.addressesPredicate
                                                                                completion:^(AddressData *selectedAddress)
            {
                self.address = selectedAddress;
                [self reloadAddressCell];
            }];

            [self.navigationController pushViewController:viewController animated:YES];
            break;
        }
        case TableSectionBuy:
        {
            if (([self isAddressRequired] && self.address != nil) || ![self isAddressRequired])
            {
                NSLog(@"//#### Do the work earlier done in BuyNumberViewController.");
            }
            else
            {
                NSString*   title;
                NSString*   message;

                title   = NSLocalizedStringWithDefaultValue(@"NumberArea AddressRequiredTitle", nil,
                                                            [NSBundle mainBundle], @"Address Required",
                                                            @"Alert title telling that user did not fill in all information.\n"
                                                            @"[iOS alert title size].");
                if (/*requireProof//#####*/YES)
                {
                    message = NSLocalizedStringWithDefaultValue(@"NumberArea AddressWithProofRequiredMessage", nil,
                                                                [NSBundle mainBundle],
                                                                @"A contact address with verification image are "
                                                                @"required for this type of Number in this area."
                                                                @"\n\nGo and add or select an address.",
                                                                @"Alert message telling that user did not fill in all information.\n"
                                                                @"[iOS alert message size]");
                }
                else
                {
                    message = NSLocalizedStringWithDefaultValue(@"NumberArea IncompleteAlertMessage", nil,
                                                                [NSBundle mainBundle],
                                                                @"A contact address is required for this Number."
                                                                @"\n\nGo and add or select an address.",
                                                                @"Alert message telling that user did not fill in all information.\n"
                                                                @"[iOS alert message size]");
                }
                
                [BlockAlertView showAlertViewWithTitle:title
                                               message:message
                                            completion:^(BOOL cancelled, NSInteger buttonIndex)
                {
                    if (cancelled)
                    {
                        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                    }
                    else
                    {
                        NSIndexPath* indexPath = [NSIndexPath indexPathForItem:1 inSection:TableSectionAddress];
                        [self tableView:tableView didSelectRowAtIndexPath:indexPath];
                    }
                }
                                     cancelButtonTitle:[Strings closeString]
                                     otherButtonTitles:[Strings goString], nil];
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
        case TableSectionBuy:     cell = [self actionCellForRowAtIndexPath:indexPath];  break;
    }

    return cell;
}


- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    CGFloat height;

    switch ([Common nthBitSet:indexPath.section inValue:sections])
    {
        case TableSectionArea:    height = [super tableView:tableView heightForRowAtIndexPath:indexPath]; break;
        case TableSectionName:    height = [super tableView:tableView heightForRowAtIndexPath:indexPath]; break;
        case TableSectionAddress: height = [super tableView:tableView heightForRowAtIndexPath:indexPath]; break;
        case TableSectionBuy:     height = self.buyCellHeight;                                            break;
    }

    return height;
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
        case AreaRowType:
        {
            cell.textLabel.text       = [Strings typeString];
            cell.detailTextLabel.text = [NumberType localizedStringForNumberTypeMask:numberTypeMask];
            cell.imageView.image      = nil;
            break;
        }
        case AreaRowAreaCode:
        {
            cell.textLabel.text       = [Strings areaCodeString];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"+%@ %@",
                                                                   [Common callingCodeForCountry:numberIsoCountryCode],
                                                                   areaCode];
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
        textField.tag = TextFieldCellTag;
    }
    else
    {
        textField = (UITextField*)[cell viewWithTag:TextFieldCellTag];
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
    
    cell.textLabel.text            = NSLocalizedString(@"Address", @"Address cell title");
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
        NSString* placeholder = [self isAddressRequired] ? [Strings requiredString] : [Strings optionalString];
        cell.detailTextLabel.text   = self.address ? self.address.name : placeholder;
    }

    return cell;
}


- (UITableViewCell*)actionCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    self.buyCell = [self.tableView dequeueReusableCellWithIdentifier:@"NumberBuyCell" forIndexPath:indexPath];
    self.buyCell.delegate = self;
    [self updateBuyCell];

    return self.buyCell;
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
    //####[self save];
    
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
