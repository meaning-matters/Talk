//
//  NumberExtendViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 13/07/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import "NumberExtendViewController.h"
#import "PurchaseManager.h"
#import "Common.h"
#import "Strings.h"
#import "BlockAlertView.h"
#import "WebClient.h"
#import "DataManager.h"


@interface NumberExtendViewController ()

@property (nonatomic, strong) NumberData*    number;
@property (nonatomic, copy) void (^completion)(void);

@end


@implementation NumberExtendViewController

- (instancetype)initWithNumber:(NumberData*)number completion:(void (^)(void))completion
{
    if (self = [super initWithMonthFee:number.monthFee oneTimeFee:number.renewFee])
    {
        self.number     = number;
        self.completion = completion;
    }

    return self;
}


#pragma mark - Baseclass Overrides

- (NSString*)oneTimeTitle
{
    return NSLocalizedStringWithDefaultValue(@"NumberPay ...", nil, [NSBundle mainBundle],
                                             @"%@ extend fee",
                                             @"£2.34 extend fee");
}


- (void)payNumber
{
    [[WebClient sharedClient] extendNumberE164:self.number.e164
                                     forMonths:self.payMonths
                                         reply:^(NSError* error,
                                                 float    monthFee,
                                                 float    renewFee,
                                                 NSDate*  expiryDate)
    {
        if (error == nil)
        {
            self.number.monthFee   = monthFee;
            self.number.renewFee   = renewFee;
            self.number.expiryDate = expiryDate;

            [[DataManager sharedManager] saveManagedObjectContext:nil];

            self.completion ? self.completion() : 0;

            [[AppDelegate appDelegate] checkCreditWithCompletion:^(BOOL success, NSError *error)
            {
                [self leaveViewController];
            }];
        }
        else
        {
            NSString* title;
            NSString* message;

            title   = NSLocalizedStringWithDefaultValue(@"BuyNumber FailedBuyNumberTitle", nil,
                                                        [NSBundle mainBundle], @"Extending Number Failed",
                                                        @"Alert title: A phone number could not be bought.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"BuyNumber FailedBuyNumberMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Something went wrong while extending your number: %@\n\n"
                                                        @"Please try again later.",
                                                        @"Message telling that extending a phone number failed\n"
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
    [self.navigationController popViewControllerAnimated:YES];
}

@end
