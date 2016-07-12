//
//  NumberPayViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 09/07/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import "NumberPayViewController.h"
#import "NumberPayCell.h"
#import "UIViewController+Common.h"
#import "PurchaseManager.h"
#import "Common.h"
#import "Strings.h"
#import "BlockAlertView.h"
#import "WebClient.h"
#import "NumberData.h"
#import "DataManager.h"


@interface NumberPayViewController () <NumberPayCellDelegate>

@property (nonatomic, assign) float          monthFee;
@property (nonatomic, assign) float          oneTimeFee;
@property (nonatomic, assign) float          isExtension;
@property (nonatomic, strong) NSString*      name;
@property (nonatomic, assign) NumberTypeMask numberTypeMask;
@property (nonatomic, strong) NSString*      isoCountryCode;
@property (nonatomic, strong) NSDictionary*  area;
@property (nonatomic, strong) NSString*      areaCode;
@property (nonatomic, strong) NSString*      areaName;
@property (nonatomic, strong) NSDictionary*  state;
@property (nonatomic, strong) NSString*      areaId;
@property (nonatomic, strong) AddressData*   address;
@property (nonatomic, strong) NumberPayCell* payCell;
@property (nonatomic, assign) CGFloat        payCellHeight;
@property (nonatomic, assign) int            payMonths;

@end


@implementation NumberPayViewController

- (instancetype)initWithMonthFee:(float)monthFee
                      oneTimeFee:(float)oneTimeFee
                     isExtension:(BOOL)isExtension
                            name:(NSString*)name
                  numberTypeMask:(NumberTypeMask)numberTypeMask
                  isoCountryCode:(NSString*)isoCountryCode
                            area:(NSDictionary*)area
                        areaCode:(NSString*)areaCode
                        areaName:(NSString*)areaName
                           state:(NSDictionary*)state
                         areadId:(NSString*)areaId
                         address:(AddressData*)address
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        _monthFee       = monthFee;
        _oneTimeFee     = oneTimeFee;
        _isExtension    = isExtension;
        _name           = name;
        _numberTypeMask = numberTypeMask;
        _isoCountryCode = isoCountryCode;
        _area           = area;
        _areaCode       = areaCode;
        _areaName       = areaName;
        _state          = state;
        _areaId         = areaId;
        _address        = address;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem* barButtonItem;
    barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                  target:self
                                                                  action:@selector(cancelAction)];
    self.navigationItem.rightBarButtonItem = barButtonItem;

    [self.tableView registerNib:[UINib nibWithNibName:@"NumberPayCell" bundle:nil]
         forCellReuseIdentifier:@"NumberPayCell"];

    self.payCell       = [self.tableView dequeueReusableCellWithIdentifier:@"NumberPayCell"];
    self.payCellHeight = self.payCell.bounds.size.height;

    [self setupFootnotesHandlingOnTableView:self.tableView];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}


- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"NumberPayCell" forIndexPath:indexPath];

    self.payCell = (NumberPayCell*)cell;
    self.payCell.delegate = self;
    [self updatePayCell];

    return cell;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString* title;

    if (self.oneTimeFee == 0.0f)
    {
        title = NSLocalizedStringWithDefaultValue(@"NumberPay:... NooneTimeFeeTableFooter", nil, [NSBundle mainBundle],
                                                  @"The fee will be taken from your Credit. If your Credit "
                                                  @"is too low, you'll be asked to buy more.",
                                                  @"[Multiple lines]");
    }
    else
    {
        title = NSLocalizedStringWithDefaultValue(@"NumberPay:... TableFooter", nil, [NSBundle mainBundle],
                                                  @"The fee(s) will be taken from your Credit. If your Credit "
                                                  @"is too low, you'll be asked to buy more.",
                                                  @"[Multiple lines]");

        title = [NSString stringWithFormat:title, [self stringForFee:self.oneTimeFee]];
    }

    return title;
}


- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return self.payCellHeight;
}


#pragma mark - Actions

- (void)cancelAction
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Helpers

- (int)monthsForN:(int)n
{
    int months;
    switch (n)
    {
        case 0: months =  1; break;
        case 1: months =  2; break;
        case 2: months =  3; break;
        case 3: months =  4; break;
        case 4: months =  6; break;
        case 5: months =  9; break;
        case 6: months = 12; break;
    }

    return months;
}


- (UIButton*)buttonForN:(int)n
{
    UIButton* button;
    switch (n)
    {
        case 0: button = self.payCell.button1;  break;
        case 1: button = self.payCell.button2;  break;
        case 2: button = self.payCell.button3;  break;
        case 3: button = self.payCell.button4;  break;
        case 4: button = self.payCell.button6;  break;
        case 5: button = self.payCell.button9;  break;
        case 6: button = self.payCell.button12; break;
    }

    return button;
}


- (UIActivityIndicatorView*)indicatorForN:(int)n
{
    UIActivityIndicatorView* indicator;
    switch (n)
    {
        case 0: indicator = self.payCell.activityIndicator1;  break;
        case 1: indicator = self.payCell.activityIndicator2;  break;
        case 2: indicator = self.payCell.activityIndicator3;  break;
        case 3: indicator = self.payCell.activityIndicator4;  break;
        case 4: indicator = self.payCell.activityIndicator6;  break;
        case 5: indicator = self.payCell.activityIndicator9;  break;
        case 6: indicator = self.payCell.activityIndicator12; break;
    }

    return indicator;
}


- (void)updatePayCell
{
    for (int n = 0; n <= 6; n++)
    {
        int                      months    = [self monthsForN:n];
        UIButton*                button    = [self buttonForN:n];
        UIActivityIndicatorView* indicator = [self indicatorForN:n];
        NSString*                monthsTitle;
        NSString*                oneTimeTitle;

        if (months == 1)
        {
            monthsTitle = NSLocalizedStringWithDefaultValue(@"NumberPay OneMonthFee", nil, [NSBundle mainBundle],
                                                            @"%@ for 1 month",
                                                            @"£2.34 for 1 month");
        }
        else
        {
            monthsTitle = NSLocalizedStringWithDefaultValue(@"NumberPay MultipleMonthsFee", nil, [NSBundle mainBundle],
                                                            @"%@ for %d months",
                                                            @"£2.34 for 4 months");
        }

        monthsTitle = [NSString stringWithFormat:monthsTitle, [self stringForFee:(months * self.monthFee)], months];

        if (self.isExtension)
        {
            oneTimeTitle = NSLocalizedStringWithDefaultValue(@"NumberPay ...", nil, [NSBundle mainBundle],
                                                             @"%@ extend fee",
                                                             @"£2.34 extend fee");
            oneTimeTitle = [NSString stringWithFormat:oneTimeTitle, [self stringForFee:self.oneTimeFee]];
        }
        else
        {
            if (self.oneTimeFee > 0.0f)
            {
                oneTimeTitle = NSLocalizedStringWithDefaultValue(@"NumberPay ...", nil, [NSBundle mainBundle],
                                                                 @"%@ setup fee",
                                                                 @"£2.34 setup fee");
                oneTimeTitle = [NSString stringWithFormat:oneTimeTitle, [self stringForFee:self.oneTimeFee]];
            }
            else
            {
                oneTimeTitle = NSLocalizedStringWithDefaultValue(@"NumberPay ...", nil, [NSBundle mainBundle],
                                                                 @"(no setup fee)",
                                                                 @"");
            }
        }

        NSString* title = [NSString stringWithFormat:@"%@\n%@", monthsTitle, oneTimeTitle];

        [Common styleButton:button];
        [button setTitle:title forState:UIControlStateNormal];

        button.alpha                  = (self.payMonths != 0) ? 0.5 : 1.0;
        button.userInteractionEnabled = (self.payMonths == 0);
        (months == self.payMonths) ? [indicator startAnimating] : [indicator stopAnimating];
    }
}


- (NSString*)stringForFee:(float)fee
{
    return [[PurchaseManager sharedManager] localizedFormattedPrice:fee];
}


- (void)saveNumberE164:(NSString*)e164 purchaseDate:(NSDate*)purchaseDate renewalDate:(NSDate*)renewalDate
{
    NSManagedObjectContext* managedObjectContext = [DataManager sharedManager].managedObjectContext;
    NumberData*             number;

    number = [NSEntityDescription insertNewObjectForEntityForName:@"Number"
                                           inManagedObjectContext:managedObjectContext];

    number.name           = self.name;
    number.e164           = e164;
    number.numberType     = [NumberType stringForNumberTypeMask:self.numberTypeMask];
    number.areaCode       = self.areaCode;
    number.areaName       = [Common capitalizedString:self.areaName];
    number.stateCode      = self.state[@"stateCode"];
    number.stateName      = self.state[@"stateName"];
    number.isoCountryCode = self.isoCountryCode;
    number.address        = self.address;
    number.addressType    = self.area[@"addressType"];
    number.proofTypes     = self.area[@"proofTypes"];
    number.purchaseDate   = purchaseDate;
    number.renewalDate    = renewalDate;
    number.autoRenew      = @(YES);
    number.fixedRate      = [self.area[@"fixedRate"] floatValue];
    number.fixedSetup     = [self.area[@"fixedSetup"] floatValue];
    number.mobileRate     = [self.area[@"mobileRate"] floatValue];
    number.mobileSetup    = [self.area[@"mobileSetup"] floatValue];
    number.payphoneRate   = [self.area[@"payphoneRate"] floatValue];
    number.payphoneSetup  = [self.area[@"payphoneSetup"] floatValue];

    [[DataManager sharedManager] saveManagedObjectContext:managedObjectContext];
}


#pragma mark - Number Pay Cell Delegate

- (void)payNumberForMonths:(int)months
{
    self.payMonths = months;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [self updatePayCell];
    void (^payNumberBlock)(void) = ^
    {
        [[WebClient sharedClient] purchaseNumberForMonths:months
                                                     name:self.name
                                           isoCountryCode:self.isoCountryCode
                                                   areaId:self.areaId
                                                addressId:self.address.addressId
                                                autoRenew:YES
                                                    reply:^(NSError*  error,
                                                            NSString* e164,
                                                            NSDate*   purchaseDate,
                                                            NSDate*   renewalDate)
         {
             if (error == nil)
             {
                 [self saveNumberE164:e164 purchaseDate:purchaseDate renewalDate:renewalDate];
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
        float totalFee = self.oneTimeFee + (self.monthFee * self.payMonths);
        if (error == nil)
        {
            if (totalFee < credit)
            {
                payNumberBlock();
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
                                    payNumberBlock();
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
                            self.payMonths = 0;
                            self.navigationItem.rightBarButtonItem.enabled = YES;
                            [self updatePayCell];
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

@end
