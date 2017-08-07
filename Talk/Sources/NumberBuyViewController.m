//
//  NumberBuyViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 09/07/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import "NumberBuyViewController.h"
#import "NumberDestinationsViewController.h"
#import "DestinationViewController.h"
#import "PurchaseManager.h"
#import "Common.h"
#import "Strings.h"
#import "BlockAlertView.h"
#import "WebClient.h"
#import "NumberData.h"
#import "DataManager.h"


@interface NumberBuyViewController ()

@property (nonatomic, strong) NSString*      name;
@property (nonatomic, assign) NumberTypeMask numberTypeMask;
@property (nonatomic, strong) NSString*      isoCountryCode;
@property (nonatomic, strong) NSDictionary*  area;
@property (nonatomic, strong) NSString*      areaCode;
@property (nonatomic, strong) NSString*      areaName;
@property (nonatomic, strong) NSDictionary*  state;
@property (nonatomic, strong) NSString*      areaId;
@property (nonatomic, strong) AddressData*   address;
@property (nonatomic, assign) BOOL           autoRenew; //### NO for now.

@end


@implementation NumberBuyViewController

- (instancetype)initWithMonthFee:(float)monthFee
                        setupFee:(float)setupFee
                            name:(NSString*)name
                  numberTypeMask:(NumberTypeMask)numberTypeMask
                  isoCountryCode:(NSString*)isoCountryCode
                           state:(NSDictionary*)state
                            area:(NSDictionary*)area
                        areaCode:(NSString*)areaCode
                        areaName:(NSString*)areaName
                         areadId:(NSString*)areaId
                         address:(AddressData*)address
{
    if (self = [super initWithMonthFee:monthFee oneTimeFee:setupFee])
    {
        _name           = name;
        _numberTypeMask = numberTypeMask;
        _isoCountryCode = isoCountryCode;
        _area           = area;
        _areaCode       = areaCode;
        _areaName       = areaName;
        _state          = state;
        _areaId         = areaId;
        _address        = address;
        _autoRenew      = NO; //### NO for now.
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
}


#pragma mark - Baseclass Overrides

- (NSString*)oneTimeTitle
{
    return NSLocalizedStringWithDefaultValue(@"NumberPay ...", nil, [NSBundle mainBundle],
                                             @"%@ setup fee",
                                             @"£2.34 setup fee");
}


- (void)payNumber
{
    [[WebClient sharedClient] purchaseNumberForMonths:self.payMonths
                                                 name:self.name
                                       isoCountryCode:self.isoCountryCode
                                               areaId:self.areaId
                                          addressUuid:self.address.uuid
                                            autoRenew:self.autoRenew
                                                reply:^(NSError*  error,
                                                        NSString* uuid,
                                                        NSString* e164,
                                                        NSDate*   purchaseDate,
                                                        NSDate*   expiryDate,
                                                        float     monthFee,
                                                        float     renewFee)
    {
        if (error == nil)
        {
            [[AppDelegate appDelegate] checkCreditWithCompletion:nil];

            NumberData* number = [self saveNumberWithUuid:uuid
                                                     e164:e164
                                             purchaseDate:purchaseDate
                                               expiryDate:expiryDate
                                                 monthFee:monthFee
                                                 renewFee:renewFee];

            [self dismissViewControllerAnimated:YES completion:^
            {
                UINavigationController* navigationController;

                if ([[DataManager sharedManager] fetchEntitiesWithName:@"Destination"].count == 0)
                {
                    DestinationViewController* viewController;
                    viewController = [[DestinationViewController alloc] initWithCompletion:^(DestinationData* destination)
                    {
                        if (destination != nil)
                        {
                            NSString* destinationUuid = (destination == nil) ? @"" : destination.uuid;
                            [[WebClient sharedClient] updateNumberWithUuid:number.uuid
                                                                      name:nil
                                                                 autoRenew:number.autoRenew
                                                           destinationUuid:destinationUuid
                                                               addressUuid:nil
                                                                     reply:^(NSError*  error,
                                                                             NSString* e164,
                                                                             NSDate*   purchaseDate,
                                                                             NSDate*   expiryDate,
                                                                             float     monthFee,
                                                                             float     renewFee)
                            {
                                if (error == nil)
                                {
                                    number.destination = destination;
                                    [[DataManager sharedManager] saveManagedObjectContext:nil];
                                }
                                else
                                {
                                    [Common showSetDestinationError:error completion:nil];
                                }
                            }];
                        }
                    }];

                    navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
                    navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                }
                else
                {
                    NumberDestinationsViewController* viewController;
                    viewController = [[NumberDestinationsViewController alloc] initWithNumber:number];

                    navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
                    navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                }

                [[Common topViewController] presentViewController:navigationController animated:YES completion:nil];
            }];
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
                [self leaveViewController];
            }
                                 cancelButtonTitle:[Strings closeString]
                                 otherButtonTitles:nil];
        }
    }];
}


- (void)leaveViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Actions

- (void)cancelAction
{
    [self leaveViewController];
}


#pragma mark - Helpers

- (NumberData*)saveNumberWithUuid:(NSString*)uuid
                             e164:(NSString*)e164
                     purchaseDate:(NSDate*)purchaseDate
                       expiryDate:(NSDate*)expiryDate
                         monthFee:(float)monthFee
                         renewFee:(float)renewFee
{
    NSManagedObjectContext* managedObjectContext = [DataManager sharedManager].managedObjectContext;
    NumberData*             number;

    number = [NSEntityDescription insertNewObjectForEntityForName:@"Number"
                                           inManagedObjectContext:managedObjectContext];

    number.uuid               = uuid;
    number.name               = self.name;
    number.e164               = e164;
    number.numberType         = [NumberType stringForNumberTypeMask:self.numberTypeMask];
    number.areaCode           = self.areaCode;
    number.areaName           = [Common capitalizedString:self.areaName];
    number.areaId             = self.areaId;
    number.stateCode          = self.state[@"stateCode"];
    number.stateName          = self.state[@"stateName"];
    number.isoCountryCode     = self.isoCountryCode;
    number.address            = self.address;
    number.addressType        = self.area[@"addressType"];
    number.purchaseDate       = purchaseDate;
    number.expiryDate         = expiryDate;
    number.notifiedExpiryDays = INT16_MAX;  // Indicated not notified yet.
    number.monthFee           = monthFee;
    number.renewFee           = renewFee;
    number.autoRenew          = self.autoRenew;
    number.fixedRate          = [self.area[@"fixedRate"] floatValue];
    number.fixedSetup         = [self.area[@"fixedSetup"] floatValue];
    number.mobileRate         = [self.area[@"mobileRate"] floatValue];
    number.mobileSetup        = [self.area[@"mobileSetup"] floatValue];
    number.payphoneRate       = [self.area[@"payphoneRate"] floatValue];
    number.payphoneSetup      = [self.area[@"payphoneSetup"] floatValue];

    [[DataManager sharedManager] saveManagedObjectContext:managedObjectContext];

    return number;
}

@end
