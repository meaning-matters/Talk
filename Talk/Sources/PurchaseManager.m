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
NSString* const  PurchaseManagerProductIdentifierNumber1  = PRODUCT_IDENTIFIER_BASE @"Number1";
NSString* const  PurchaseManagerProductIdentifierNumber2  = PRODUCT_IDENTIFIER_BASE @"Number2";
NSString* const  PurchaseManagerProductIdentifierNumber3  = PRODUCT_IDENTIFIER_BASE @"Number3";
NSString* const  PurchaseManagerProductIdentifierNumber4  = PRODUCT_IDENTIFIER_BASE @"Number4";
NSString* const  PurchaseManagerProductIdentifierNumber5  = PRODUCT_IDENTIFIER_BASE @"Number5";
NSString* const  PurchaseManagerProductIdentifierNumber6  = PRODUCT_IDENTIFIER_BASE @"Number6";
NSString* const  PurchaseManagerProductIdentifierNumber7  = PRODUCT_IDENTIFIER_BASE @"Number7";
NSString* const  PurchaseManagerProductIdentifierNumber8  = PRODUCT_IDENTIFIER_BASE @"Number8";
NSString* const  PurchaseManagerProductIdentifierNumber9  = PRODUCT_IDENTIFIER_BASE @"Number9";
NSString* const  PurchaseManagerProductIdentifierNumber10 = PRODUCT_IDENTIFIER_BASE @"Number10";
NSString* const  PurchaseManagerProductIdentifierNumber11 = PRODUCT_IDENTIFIER_BASE @"Number11";
NSString* const  PurchaseManagerProductIdentifierNumber12 = PRODUCT_IDENTIFIER_BASE @"Number12";
NSString* const  PurchaseManagerProductIdentifierNumber13 = PRODUCT_IDENTIFIER_BASE @"Number13";
NSString* const  PurchaseManagerProductIdentifierNumber14 = PRODUCT_IDENTIFIER_BASE @"Number15";
NSString* const  PurchaseManagerProductIdentifierNumber15 = PRODUCT_IDENTIFIER_BASE @"Number16";
NSString* const  PurchaseManagerProductIdentifierNumber16 = PRODUCT_IDENTIFIER_BASE @"Number1";
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

@synthesize currencyCode = _currencyCode;

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
                                            PurchaseManagerProductIdentifierNumber1,
                                            PurchaseManagerProductIdentifierNumber2,
                                            PurchaseManagerProductIdentifierNumber3,
                                            PurchaseManagerProductIdentifierNumber4,
                                            PurchaseManagerProductIdentifierNumber5,
                                            PurchaseManagerProductIdentifierNumber6,
                                            PurchaseManagerProductIdentifierNumber7,
                                            PurchaseManagerProductIdentifierNumber8,
                                            PurchaseManagerProductIdentifierNumber9,
                                            PurchaseManagerProductIdentifierNumber10,
                                            PurchaseManagerProductIdentifierNumber11,
                                            PurchaseManagerProductIdentifierNumber12,
                                            PurchaseManagerProductIdentifierNumber13,
                                            PurchaseManagerProductIdentifierNumber14,
                                            PurchaseManagerProductIdentifierNumber15,
                                            PurchaseManagerProductIdentifierNumber16,
                                            PurchaseManagerProductIdentifierCredit1,
                                            PurchaseManagerProductIdentifierCredit2,
                                            PurchaseManagerProductIdentifierCredit5,
                                            PurchaseManagerProductIdentifierCredit10,
                                            PurchaseManagerProductIdentifierCredit20,
                                            PurchaseManagerProductIdentifierCredit50, nil];

        [[SKPaymentQueue defaultQueue] addTransactionObserver:sharedManager];

        // Load the products each time the app starts.
        __block id  observer;
        observer = [[NSNotificationCenter defaultCenter] addObserverForName:NetworkStatusReachableNotification
                                                                     object:nil
                                                                      queue:[NSOperationQueue mainQueue]
                                                                 usingBlock:^(NSNotification* notification)
        {
            NetworkStatusReachable reachable = [notification.userInfo[@"status"] intValue];

            if ((reachable == NetworkStatusReachableWifi || reachable == NetworkStatusReachableCellular) &&
                sharedManager.productsRequest == nil && sharedManager.products == nil)
            {
                // At first time the app gets connected to internet.
                [sharedManager loadProducts];
            }

            if (sharedManager.products != nil)
            {
                // At subsequent time the app get connected to internet,
                // and when products loaded & transactions restored at earlier time.
                [[NSNotificationCenter defaultCenter] removeObserver:observer];
            }
        }];
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
    return ([productIdentifier isEqualToString:PurchaseManagerProductIdentifierNumber1]  ||
            [productIdentifier isEqualToString:PurchaseManagerProductIdentifierNumber2]  ||
            [productIdentifier isEqualToString:PurchaseManagerProductIdentifierNumber3]  ||
            [productIdentifier isEqualToString:PurchaseManagerProductIdentifierNumber4]  ||
            [productIdentifier isEqualToString:PurchaseManagerProductIdentifierNumber5]  ||
            [productIdentifier isEqualToString:PurchaseManagerProductIdentifierNumber6]  ||
            [productIdentifier isEqualToString:PurchaseManagerProductIdentifierNumber7]  ||
            [productIdentifier isEqualToString:PurchaseManagerProductIdentifierNumber8]  ||
            [productIdentifier isEqualToString:PurchaseManagerProductIdentifierNumber9]  ||
            [productIdentifier isEqualToString:PurchaseManagerProductIdentifierNumber10] ||
            [productIdentifier isEqualToString:PurchaseManagerProductIdentifierNumber11] ||
            [productIdentifier isEqualToString:PurchaseManagerProductIdentifierNumber12] ||
            [productIdentifier isEqualToString:PurchaseManagerProductIdentifierNumber13] ||
            [productIdentifier isEqualToString:PurchaseManagerProductIdentifierNumber14] ||
            [productIdentifier isEqualToString:PurchaseManagerProductIdentifierNumber15] ||
            [productIdentifier isEqualToString:PurchaseManagerProductIdentifierNumber16]);
}


- (BOOL)isCreditProductIdentifier:(NSString*)productIdentifier
{
    return ([productIdentifier isEqualToString:PurchaseManagerProductIdentifierCredit1]  ||
            [productIdentifier isEqualToString:PurchaseManagerProductIdentifierCredit2]  ||
            [productIdentifier isEqualToString:PurchaseManagerProductIdentifierCredit5]  ||
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
#warning Good place of this?
    if ([[AppDelegate appDelegate].deviceToken length] == 0)
    {
        NSLog(@"//### Device Token not available (yet).");
        
        return;
    }

    NSMutableDictionary*    parameters = [NSMutableDictionary dictionary];
    parameters[@"receipt"] = [Base64 encode:transaction.transactionReceipt];

    [[WebClient sharedClient] retrieveWebAccount:parameters
                                           reply:^(WebClientStatus status, id content)
    {
        if (status == WebClientStatusOk)
        {
            [Settings sharedSettings].webUsername = ((NSDictionary*)content)[@"username"];
            [Settings sharedSettings].webPassword = ((NSDictionary*)content)[@"password"];

            NSMutableDictionary*    parameters = [NSMutableDictionary dictionary];
            parameters[@"deviceName"]        = [UIDevice currentDevice].name;
            parameters[@"notificationToken"] = [AppDelegate appDelegate].deviceToken;
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

            [[WebClient sharedClient] retrieveSipAccount:parameters
                                                   reply:^(WebClientStatus status, id content)
            {
                if (status == WebClientStatusOk)
                {
                    [Settings sharedSettings].sipServer   = ((NSDictionary*)content)[@"sipRealm"];
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
    [Common enableNetworkActivityIndicator:NO];

    self.productsRequest = nil;
    self.products = response.products;

    for (SKProduct* product in self.products)
    {
        // Calculate the currency conversion rate for all Credits and take the highest.
        // We also loop over all credit products, instead of taking just one, to prevent
        // that this calculation breaks when products are disabled in iTunesConnect.        
        if ([self isCreditProductIdentifier:product.productIdentifier])
        {
            float       usdPrice = [self usdCreditOfProductIdentifier:product.productIdentifier];
            float       rate = product.price.doubleValue / usdPrice;

            _currencyCode = [product.priceLocale objectForKey:NSLocaleCurrencyCode];

            if (self.currencyRate == 0 || rate > self.currencyRate)
            {
                self.currencyRate = rate;
            }
        }
    }
}


- (void)request:(SKRequest*)request didFailWithError:(NSError*)error
{
    NSString*   title;
    NSString*   message;

    [Common enableNetworkActivityIndicator:NO];

    title = NSLocalizedStringWithDefaultValue(@"Purchase:General ProductLoadFailAlertTitle", nil,
                                              [NSBundle mainBundle], @"Loading Products Failed",
                                              @"Alert title telling in-app purchases are disabled.\n"
                                              @"[iOS alert title size - abbreviated: 'Can't Pay'].");
    message = NSLocalizedStringWithDefaultValue(@"Purchase:General ProductLoadFailAlertMessage", nil,
                                                [NSBundle mainBundle],
                                                @"Loading the In-App Purchase products from the iTunes Store "
                                                @"failed: %@.\nPlease try again later.",
                                                @"Alert message: Information could not be loaded over internet.\n"
                                                @"[iOS alert message size]");
    message = [NSString stringWithFormat:message, [error localizedDescription]];
    [BlockAlertView showAlertViewWithTitle:title
                                   message:message
                                completion:nil
                         cancelButtonTitle:[CommonStrings closeString]
                         otherButtonTitles:nil];

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

    if (self.accountCompletion != nil)
    {
        self.accountCompletion(NO, error);
    }
    
    self.accountCompletion    = nil;
    self.restoredTransactions = nil;
}


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
                            NSLog(@"//### transaction was not finished yet");
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

- (void)loadProducts
{
    self.productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:self.productIdentifiers];
    self.productsRequest.delegate = self;
    [self.productsRequest start];

    [Common enableNetworkActivityIndicator:YES];
}


- (NSString*)productIdentifierForNumberTier:(int)tier
{
    NSString*   identifier = [NSString stringWithFormat: PRODUCT_IDENTIFIER_BASE @"Number%d", tier];

    return [self getProductForProductIdentifier:identifier].productIdentifier;
}


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


- (NSString*)localizedPriceForProductIdentifier:(NSString*)identifier;
{
    SKProduct*  product = [self getProductForProductIdentifier:identifier];
    NSString*   priceString;

    if (product != nil)
    {
        NSNumberFormatter*  numberFormatter;

        numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [numberFormatter setLocale:product.priceLocale];

        priceString = [numberFormatter stringFromNumber:product.price];
    }
    else
    {
#warning //### Handle this!!!
        priceString = @"----";
    }

    return priceString;
}


- (void)restoreOrBuyAccount:(void (^)(BOOL success, id object))completion
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

@end
