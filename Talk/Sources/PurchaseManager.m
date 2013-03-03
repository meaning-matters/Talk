//
//  PurchaseManager.m
//  Talk
//
//  Created by Cornelis van der Bent on 24/01/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

// Test accounts: aaa@nb.aaa Qwertu1 (aaa/bbb/ccc/ddd).

#import "PurchaseManager.h"
#import "NetworkStatus.h"
#import "Common.h"
#import "CommonStrings.h"
#import "BlockAlertView.h"
#import "Base64.h"
#import "WebClient.h"
#import "Settings.h"


// These must match perfectly to what's in iTunesConnect for this app!
#warning MAKE SURE TO UPDATE PRODUCT_IDENTIFIER_BASE WHEN MOVING TO FINAL APP ACCOUNT
#define PRODUCT_IDENTIFIER_BASE @"com.numberbay0."
NSString* const  PurchaseManagerProductIdentifierAccount  = PRODUCT_IDENTIFIER_BASE @"Account";
NSString* const  PurchaseManagerProductIdentifierNumber   = PRODUCT_IDENTIFIER_BASE @"Number";
NSString* const  PurchaseManagerProductIdentifierCredit1  = PRODUCT_IDENTIFIER_BASE @"Credit1";
NSString* const  PurchaseManagerProductIdentifierCredit2  = PRODUCT_IDENTIFIER_BASE @"Credit2";
NSString* const  PurchaseManagerProductIdentifierCredit5  = PRODUCT_IDENTIFIER_BASE @"Credit5";
NSString* const  PurchaseManagerProductIdentifierCredit10 = PRODUCT_IDENTIFIER_BASE @"Credit10";
NSString* const  PurchaseManagerProductIdentifierCredit20 = PRODUCT_IDENTIFIER_BASE @"Credit20";
NSString* const  PurchaseManagerProductIdentifierCredit50 = PRODUCT_IDENTIFIER_BASE @"Credit50";


@interface PurchaseManager () <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (nonatomic, strong) NSSet*                productIdentifiers;
@property (nonatomic, strong) SKProductsRequest*    productsRequest;
@property (nonatomic, copy) void (^accountCompletion)(BOOL success, id object);
@property (nonatomic, strong) NSMutableArray*       restoredTransactions;

@end


@implementation PurchaseManager

static PurchaseManager*     sharedManager;


#pragma mark - Singleton Stuff

+ (void)initialize
{
    if ([PurchaseManager class] == self)
    {
        sharedManager = [self new];
        sharedManager.delegate = sharedManager; //### Do everyting in here for now.

        sharedManager.productIdentifiers = [NSSet setWithObjects:
                                            PurchaseManagerProductIdentifierAccount,
                                            PurchaseManagerProductIdentifierNumber,
                                            PurchaseManagerProductIdentifierCredit1,
                                            PurchaseManagerProductIdentifierCredit2,
                                            PurchaseManagerProductIdentifierCredit5,
                                            PurchaseManagerProductIdentifierCredit10,
                                            PurchaseManagerProductIdentifierCredit20,
                                            PurchaseManagerProductIdentifierCredit50, nil];

        // Load the products each time the app starts.
        __block id  observer;
        observer = [[NSNotificationCenter defaultCenter] addObserverForName:NetworkStatusReachableNotification
                                                                     object:nil
                                                                      queue:[NSOperationQueue mainQueue]
                                                                 usingBlock:^(NSNotification* note)
        {
            NetworkStatusReachable reachable = [note.userInfo[@"status"] intValue];

            if ((reachable == NetworkStatusReachableWifi || reachable == NetworkStatusReachableCellular) &&
                sharedManager.productsRequest == nil && sharedManager.products == nil)
            {
                // At first time the app gets connected to internet.
                sharedManager.productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:sharedManager.productIdentifiers];
                sharedManager.productsRequest.delegate = sharedManager;
                [sharedManager.productsRequest start];
            }

            if (sharedManager.products != nil)
            {
                // At subsequent time the app get connected to internet,
                // and when products loaded & transactions restored at earlier time.
                [[NSNotificationCenter defaultCenter] removeObserver:observer];
            }
        }];

        [[SKPaymentQueue defaultQueue] addTransactionObserver:sharedManager];
    }
}


+ (id)allocWithZone:(NSZone*)zone
{
    if (sharedManager && [PurchaseManager class] == self)
    {
        [NSException raise:NSGenericException format:@"Duplicate PurchaseManager singleton creation"];
    }

    return [super allocWithZone:zone];
}


+ (PurchaseManager*)sharedManager
{
    return sharedManager;
}


#pragma mark - Helper Methods

- (SKProduct*)getProductForProductIdentifier:(NSString*)productIdentifier
{
    for (SKProduct* product in self.products)
    {
        if ([product.productIdentifier isEqualToString:productIdentifier])
        {
            return product;
        }
    }

    return nil;
}


- (BOOL)isAccountProductIdentifier:(NSString*)productIdentifier
{
    return [productIdentifier isEqualToString:PurchaseManagerProductIdentifierAccount];
}


- (BOOL)isNumberProductIdentifier:(NSString*)productIdentifier
{
    return [productIdentifier isEqualToString:PurchaseManagerProductIdentifierNumber];
}


- (BOOL)isCreditProductIdentifier:(NSString*)productIdentifier
{
    return ([productIdentifier isEqualToString:PurchaseManagerProductIdentifierCredit1] ||
            [productIdentifier isEqualToString:PurchaseManagerProductIdentifierCredit2] ||
            [productIdentifier isEqualToString:PurchaseManagerProductIdentifierCredit5] ||
            [productIdentifier isEqualToString:PurchaseManagerProductIdentifierCredit10] ||
            [productIdentifier isEqualToString:PurchaseManagerProductIdentifierCredit20] ||
            [productIdentifier isEqualToString:PurchaseManagerProductIdentifierCredit50]);
}


- (float)usdCreditOfProductIdentifier:(NSString*)productIdentifier
{
    if ([self isCreditProductIdentifier:productIdentifier])
    {
        NSRange     range = [productIdentifier rangeOfString:@"Credit"];
        NSUInteger  index = range.location + range.length;

        return [[productIdentifier substringFromIndex:index] floatValue] - 0.01f;
    }
    else
    {
        return 0;
    }
}


#pragma mark - PurchaseManagerDelegate

- (void)processAccountTransaction:(SKPaymentTransaction*)transaction
{
    if ([[AppDelegate appDelegate].deviceToken length] == 0)
    {
        NSLog(@"//### Device Token not available (yet).");
        
        return;
    }

    NSMutableDictionary*    parameters = [NSMutableDictionary dictionary];

    parameters[@"receipt"]           = [Base64 encode:transaction.transactionReceipt];
#warning Check that deviceToken is available!!  If not stop and report.
    parameters[@"notificationToken"] = [AppDelegate appDelegate].deviceToken;
    parameters[@"deviceName"]        = [UIDevice currentDevice].name;
    parameters[@"deviceOs"]          = [NSString stringWithFormat:@"%@ %@",
                                        [UIDevice currentDevice].systemName,
                                        [UIDevice currentDevice].systemVersion];
    parameters[@"deviceModel"]       = [Common deviceModel];
    parameters[@"appVersion"]        = [Common bundleVersion];

    if ([NetworkStatus sharedStatus].simMobileCountryCode != nil)
    {
        parameters[@"mobileCountryCode"] = [NetworkStatus sharedStatus].simMobileCountryCode;
    }

    if ([NetworkStatus sharedStatus].simMobileNetworkCode != nil)
    {
        parameters[@"mobileNetworkCode"] = [NetworkStatus sharedStatus].simMobileNetworkCode;
    }

    [[WebClient sharedClient] retrieveWebAccount:parameters
                                           reply:^(WebClientStatus status, id content)
    {
        if (status == WebClientStatusOk)
        {
            NSLog(@"SUCCESS: %@\nBUT WE DON'T STORE WEB ACCOUNT FOR TESTING", content);
#warning NOT STORED!!!
            return ;

            [Settings sharedSettings].webUsername = ((NSDictionary*)content)[@"username"];
            [Settings sharedSettings].webPassword = ((NSDictionary*)content)[@"password"];

            NSMutableDictionary*    parameters = [NSMutableDictionary dictionary];
            parameters[@"deviceName"] = [UIDevice currentDevice].name;
            [[WebClient sharedClient] retrieveSipAccount:parameters
                                                   reply:^(WebClientStatus status, id content)
            {
                if (status == WebClientStatusOk)
                {
                    [Settings sharedSettings].sipRealm    = ((NSDictionary*)content)[@"sipRealm"];
                    [Settings sharedSettings].sipUsername = ((NSDictionary*)content)[@"sipUsername"];
                    [Settings sharedSettings].sipPassword = ((NSDictionary*)content)[@"sipPassword"];

                    [self finishTransaction:transaction];
                    self.accountCompletion(YES, transaction);
                    self.accountCompletion = nil;
                }
                else
                {
                    NSError*    error = [[NSError alloc] initWithDomain:[Settings sharedSettings].errorDomain
                                                                   code:SKErrorUnknown  //### Make app-wide errors.
                                                               userInfo:nil];
                    self.accountCompletion(NO, error);
                    self.accountCompletion = nil;
                }
            }];
        }
        else if (status == WebClientStatusFailDeviceNameNotUnique)
        {
            NSString*   title;
            NSString*   message;

            title = NSLocalizedStringWithDefaultValue(@"Purchase:General DeviceNameNotUniqueTitle", nil,
                                                      [NSBundle mainBundle], @"Device Name Not Unique",
                                                      @"Alert title telling that the name of the device is already in "
                                                      @"use\n[iOS alert title size - abbreviated: 'Can't Pay'].");
            message = NSLocalizedStringWithDefaultValue(@"Purchase:General DeviceNameNotUniqueMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"The name of this device '%@' is already in use.\n"
                                                        @"Connect the device to your computer, go to its "
                                                        @"Summary in iTunes, and tap on the name to change it.",
                                                        @"Alert message telling that name of device is already in use.\n"
                                                        @"[iOS alert message size - use correct terms for: iTunes and "
                                                        @"Summary!]");
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:nil
                                 cancelButtonTitle:[CommonStrings closeString]
                                 otherButtonTitles:nil];
            
            self.accountCompletion(NO, nil);    // With nil as object, no additional alert will be shown.
        }
        else
        {
            // If this was a restored transaction, it already been 'finished' in updatedTransactions:.
            NSError*    error = [[NSError alloc] initWithDomain:[Settings sharedSettings].errorDomain
                                                           code:SKErrorUnknown  //### Make app-wide errors.
                                                       userInfo:nil];
            self.accountCompletion(NO, error);
            self.accountCompletion = nil;
        }
    }];
}


- (void)purchaseManager:(PurchaseManager*)purchaseManager processNumberTransaction:(SKPaymentTransaction*)transaction
{
    [purchaseManager finishTransaction:transaction];
}


- (void)purchaseManager:(PurchaseManager*)purchaseManager processCreditTransaction:(SKPaymentTransaction*)transaction
{
    [purchaseManager finishTransaction:transaction];
}


- (void)purchaseManager:(PurchaseManager*)purchaseManager restoreNumberTransaction:(SKPaymentTransaction*)transaction
{
    [purchaseManager finishTransaction:transaction];
}


#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest*)request didReceiveResponse:(SKProductsResponse*)response
{
    self.productsRequest = nil;
    self.products = response.products;

    for (SKProduct* product in self.products)
    {
        // Calculate the currency conversion rate for all Credits and take the highest.
        // We also loop over all credit products, instead of taking just one, to prevent
        // that this calculation break when products are disabled in iTunesConnect.        
        if ([self isCreditProductIdentifier:product.productIdentifier])
        {
            float       usdPrice = [self usdCreditOfProductIdentifier:product.productIdentifier];
            float       rate = product.price.doubleValue / usdPrice;

            if (self.currencyRate == 0 || rate > self.currencyRate)
            {
                self.currencyRate = rate;
            }
        }
    }
}


- (void)request:(SKRequest*)request didFailWithError:(NSError*)error
{
    NSLog(@"//### Failed to load list of products.");
    
    self.productsRequest = nil;
}


#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue*)queue
{
    NSLog(@"paymentQueueRestoreCompletedTransactionsFinished");
    SKPaymentTransaction*   accountTransaction = nil;
    [Common enableNetworkActivityIndicator:NO];

    for (SKPaymentTransaction* transaction in self.restoredTransactions)
    {
        if ([self isAccountProductIdentifier:transaction.payment.productIdentifier])
        {
            accountTransaction = transaction;
        }
        else if ([self isNumberProductIdentifier:transaction.payment.productIdentifier])
        {
            [self.delegate purchaseManager:self restoreNumberTransaction:transaction];
        }
        else
        {
            NSLog(@"//### Encountered unexpected restored transaction: %@.", transaction.payment.productIdentifier);
        }
    }

    if (accountTransaction != nil)
    {
        [self processAccountTransaction:accountTransaction];
    }
    else if (self.accountCompletion != nil)
    {
        [self buyProductIdentifier:PurchaseManagerProductIdentifierAccount];
    }
}


- (void)paymentQueue:(SKPaymentQueue*)queue restoreCompletedTransactionsFailedWithError:(NSError*)error
{
    NSLog(@"restoreCompletedTransactionsFailedWithError: %@", [error localizedDescription]);
    [Common enableNetworkActivityIndicator:NO];

    self.accountCompletion(NO, error);
    self.accountCompletion    = nil;
    self.restoredTransactions = nil;
}



/*
 [[PurchaseManager sharedManager] restoreOrBuyAccount:^(BOOL success, id object)
 {
 if (success == YES)
 {
 SKPaymentTransaction*   transaction = object;

 //### We have Web username/password now.  So now request SIP account.
 //...
 }
 else if (object != nil && ((NSError*)object).code != SKErrorPaymentCancelled)
 {
 NSString*   title;
 NSString*   message;

 title = NSLocalizedStringWithDefaultValue(@"Purchase:Failure AlertTitle", nil,
 [NSBundle mainBundle], @"Getting Account Failed",
 @"Alert title telling that getting an account failed.\n"
 @"[iOS alert title size - abbreviated: 'Account Failed'].");
 message = NSLocalizedStringWithDefaultValue(@"Purchase:Failure AlertMessage", nil,
 [NSBundle mainBundle],
 @"Something went wrong while getting your account. "
 @"try again later.\n(The payment you may have done, "
 @"is not lost.)",
 @"Alert message telling that getting an account "
 @"failed\n"
 @"[iOS alert message size]");
 [BlockAlertView showAlertViewWithTitle:title
 message:message
 completion:nil
 cancelButtonTitle:[CommonStrings closeString]
 otherButtonTitles:nil];
 }
 }];
 */

- (void)paymentQueue:(SKPaymentQueue*)queue updatedTransactions:(NSArray*)transactions
{
    for (SKPaymentTransaction* transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"//### Busy purchasing.");
                break;

            case SKPaymentTransactionStatePurchased:
                [Common enableNetworkActivityIndicator:NO];
                if ([self isAccountProductIdentifier:transaction.payment.productIdentifier])
                {
                    if (self.accountCompletion == nil)
                    {
                        // We get here when the transaction was not finished yet.
                        self.accountCompletion = ^(BOOL status, id object)
                        {
                            //  NSLog(@"//### ");
                        };
                    }

                    [self processAccountTransaction:transaction];
                }
                else if ([self isNumberProductIdentifier:transaction.payment.productIdentifier])
                {
                    [self purchaseManager:self processNumberTransaction:transaction];
                }
                else if ([self isCreditProductIdentifier:transaction.payment.productIdentifier])
                {
                    [self purchaseManager:self processCreditTransaction:transaction];
                }
                break;

            case SKPaymentTransactionStateFailed:
                [Common enableNetworkActivityIndicator:NO];
#warning //### Assume that this is only for purchase, and never happens for restore.  I asked dev forums.
                NSLog(@"//###  Transaction failed: %@.", transaction.payment.productIdentifier);
                if ([self isAccountProductIdentifier:transaction.payment.productIdentifier] &&
                    self.accountCompletion != nil)
                {
                    self.accountCompletion(NO, transaction.error);
                    self.accountCompletion = nil;
                }
                
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;

            case SKPaymentTransactionStateRestored:
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];  // Finish multiple times is allowed.
                if (self.restoredTransactions == nil)
                {
                    self.restoredTransactions = [NSMutableArray array];
                }
                
                [self.restoredTransactions addObject:transaction];
                break;
        }
    };
}


- (void)paymentQueue:(SKPaymentQueue*)queue updatedDownloads:(NSArray*)downloads
{
    // We don't have downloads.  (This method is required, that's the only reason it's here.)
}


#pragma mark - Public API

- (NSString*)localizedFormattedPrice:(float)usdPrice
{
    NSString*   formattedString;

    if (self.products != nil || self.currencyRate == 0)
    {
        NSNumberFormatter*  numberFormatter;

        numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [numberFormatter setLocale:((SKProduct*)self.products[0]).priceLocale];

        formattedString = [numberFormatter stringFromNumber:@(usdPrice * self.currencyRate)];
    }
    else
    {
        formattedString = @"";
    }

    return formattedString;
}


- (void)restoreOrBuyAccount:(void (^)(BOOL success, id object))completion;
{
    if (self.accountCompletion != nil)
    {
        completion(NO, nil);
        
        return;
    }

    if ([Common checkRemoteNotifications] == NO)
    {
        return;
    }
    else if ([[AppDelegate appDelegate].deviceToken length] == 0)
    {
        NSLog(@"//### Device token not available (yet).");

        return;
    }

    self.accountCompletion = completion;

    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    [Common enableNetworkActivityIndicator:YES];
}


- (BOOL)buyProductIdentifier:(NSString*)productIdentifier
{
    if ([SKPaymentQueue canMakePayments])
    {
        SKProduct* product = [self getProductForProductIdentifier:productIdentifier];

        if (product != nil)
        {
            SKPayment*  payment = [SKPayment paymentWithProduct:product];
            [[SKPaymentQueue defaultQueue] addPayment:payment];
            [Common enableNetworkActivityIndicator:YES];

            return YES;
        }
        else
        {
            return NO;
        }
    }
    else
    {
        NSString*   title;
        NSString*   message;

        title = NSLocalizedStringWithDefaultValue(@"Purchase:General CantPurchaseTitle", nil,
                                                  [NSBundle mainBundle], @"Can't Make Purchases",
                                                  @"Alert title telling in-app purchases are disabled.\n"
                                                  @"[iOS alert title size - abbreviated: 'Can't Pay'].");
        message = NSLocalizedStringWithDefaultValue(@"Purchase:General CantPurchaseMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"In-app purchases are disabled.\n"
                                                    @"To enable, go to iOS Settings > General > Restrictions.",
                                                    @"Alert message telling that in-app purchases are disabled.\n"
                                                    @"[iOS alert message size - use correct iOS terms for: Settings, "
                                                    @"General and Restrictions!]");
        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:nil
                             cancelButtonTitle:[CommonStrings closeString]
                             otherButtonTitles:nil];

        return NO;
    }
}


- (void)finishTransaction:(SKPaymentTransaction*)transaction
{
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}


- (void)viewWillLayoutSubviews
{
    
}
@end
