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


// These must match perfectly to what's in iTunesConnect.
#define PRODUCT_IDENTIFIER_BASE @"com.numberbay."
#define ACCOUNT                 @"Account"
#define NUMBER_SETUP            @"NumberSetup"
#define NUMBER_SUBSCRIPTION     @"NumberSubscription"
#define CREDIT                  @"Credit"
NSString* const  PurchaseManagerProductIdentifierAccount              = PRODUCT_IDENTIFIER_BASE ACCOUNT;
NSString* const  PurchaseManagerProductIdentifierNumberSetup1         = PRODUCT_IDENTIFIER_BASE NUMBER_SETUP @"1";
NSString* const  PurchaseManagerProductIdentifierNumberSetup2         = PRODUCT_IDENTIFIER_BASE NUMBER_SETUP @"2";
NSString* const  PurchaseManagerProductIdentifierNumberSetup3         = PRODUCT_IDENTIFIER_BASE NUMBER_SETUP @"3";
NSString* const  PurchaseManagerProductIdentifierNumberSetup4         = PRODUCT_IDENTIFIER_BASE NUMBER_SETUP @"4";
NSString* const  PurchaseManagerProductIdentifierNumberSetup5         = PRODUCT_IDENTIFIER_BASE NUMBER_SETUP @"5";
NSString* const  PurchaseManagerProductIdentifierNumberSetup6         = PRODUCT_IDENTIFIER_BASE NUMBER_SETUP @"6";
NSString* const  PurchaseManagerProductIdentifierNumberSetup7         = PRODUCT_IDENTIFIER_BASE NUMBER_SETUP @"7";
NSString* const  PurchaseManagerProductIdentifierNumberSetup8         = PRODUCT_IDENTIFIER_BASE NUMBER_SETUP @"8";
NSString* const  PurchaseManagerProductIdentifierNumberSetup9         = PRODUCT_IDENTIFIER_BASE NUMBER_SETUP @"9";
NSString* const  PurchaseManagerProductIdentifierNumberSetup10        = PRODUCT_IDENTIFIER_BASE NUMBER_SETUP @"10";
NSString* const  PurchaseManagerProductIdentifierNumberSetup11        = PRODUCT_IDENTIFIER_BASE NUMBER_SETUP @"11";
NSString* const  PurchaseManagerProductIdentifierNumberSetup12        = PRODUCT_IDENTIFIER_BASE NUMBER_SETUP @"12";
NSString* const  PurchaseManagerProductIdentifierNumberSetup13        = PRODUCT_IDENTIFIER_BASE NUMBER_SETUP @"13";
NSString* const  PurchaseManagerProductIdentifierNumberSetup14        = PRODUCT_IDENTIFIER_BASE NUMBER_SETUP @"14";
NSString* const  PurchaseManagerProductIdentifierNumberSetup15        = PRODUCT_IDENTIFIER_BASE NUMBER_SETUP @"15";
NSString* const  PurchaseManagerProductIdentifierNumberSetup16        = PRODUCT_IDENTIFIER_BASE NUMBER_SETUP @"16";
NSString* const  PurchaseManagerProductIdentifierNumberSetup17        = PRODUCT_IDENTIFIER_BASE NUMBER_SETUP @"17";
NSString* const  PurchaseManagerProductIdentifierNumberSetup18        = PRODUCT_IDENTIFIER_BASE NUMBER_SETUP @"18";
NSString* const  PurchaseManagerProductIdentifierNumberSetup19        = PRODUCT_IDENTIFIER_BASE NUMBER_SETUP @"19";
NSString* const  PurchaseManagerProductIdentifierNumberSetup20        = PRODUCT_IDENTIFIER_BASE NUMBER_SETUP @"20";
NSString* const  PurchaseManagerProductIdentifierNumberSubscription1  = PRODUCT_IDENTIFIER_BASE NUMBER_SUBSCRIPTION @"1";
NSString* const  PurchaseManagerProductIdentifierNumberSubscription2  = PRODUCT_IDENTIFIER_BASE NUMBER_SUBSCRIPTION @"2";
NSString* const  PurchaseManagerProductIdentifierNumberSubscription3  = PRODUCT_IDENTIFIER_BASE NUMBER_SUBSCRIPTION @"3";
NSString* const  PurchaseManagerProductIdentifierNumberSubscription4  = PRODUCT_IDENTIFIER_BASE NUMBER_SUBSCRIPTION @"4";
NSString* const  PurchaseManagerProductIdentifierNumberSubscription5  = PRODUCT_IDENTIFIER_BASE NUMBER_SUBSCRIPTION @"5";
NSString* const  PurchaseManagerProductIdentifierNumberSubscription6  = PRODUCT_IDENTIFIER_BASE NUMBER_SUBSCRIPTION @"6";
NSString* const  PurchaseManagerProductIdentifierNumberSubscription7  = PRODUCT_IDENTIFIER_BASE NUMBER_SUBSCRIPTION @"7";
NSString* const  PurchaseManagerProductIdentifierNumberSubscription8  = PRODUCT_IDENTIFIER_BASE NUMBER_SUBSCRIPTION @"8";
NSString* const  PurchaseManagerProductIdentifierNumberSubscription9  = PRODUCT_IDENTIFIER_BASE NUMBER_SUBSCRIPTION @"9";
NSString* const  PurchaseManagerProductIdentifierNumberSubscription10 = PRODUCT_IDENTIFIER_BASE NUMBER_SUBSCRIPTION @"10";
NSString* const  PurchaseManagerProductIdentifierNumberSubscription11 = PRODUCT_IDENTIFIER_BASE NUMBER_SUBSCRIPTION @"11";
NSString* const  PurchaseManagerProductIdentifierNumberSubscription12 = PRODUCT_IDENTIFIER_BASE NUMBER_SUBSCRIPTION @"12";
NSString* const  PurchaseManagerProductIdentifierNumberSubscription13 = PRODUCT_IDENTIFIER_BASE NUMBER_SUBSCRIPTION @"13";
NSString* const  PurchaseManagerProductIdentifierNumberSubscription14 = PRODUCT_IDENTIFIER_BASE NUMBER_SUBSCRIPTION @"14";
NSString* const  PurchaseManagerProductIdentifierNumberSubscription15 = PRODUCT_IDENTIFIER_BASE NUMBER_SUBSCRIPTION @"15";
NSString* const  PurchaseManagerProductIdentifierNumberSubscription16 = PRODUCT_IDENTIFIER_BASE NUMBER_SUBSCRIPTION @"16";
NSString* const  PurchaseManagerProductIdentifierNumberSubscription17 = PRODUCT_IDENTIFIER_BASE NUMBER_SUBSCRIPTION @"17";
NSString* const  PurchaseManagerProductIdentifierNumberSubscription18 = PRODUCT_IDENTIFIER_BASE NUMBER_SUBSCRIPTION @"18";
NSString* const  PurchaseManagerProductIdentifierNumberSubscription19 = PRODUCT_IDENTIFIER_BASE NUMBER_SUBSCRIPTION @"19";
NSString* const  PurchaseManagerProductIdentifierNumberSubscription20 = PRODUCT_IDENTIFIER_BASE NUMBER_SUBSCRIPTION @"20";
NSString* const  PurchaseManagerProductIdentifierCredit1              = PRODUCT_IDENTIFIER_BASE CREDIT @"1";
NSString* const  PurchaseManagerProductIdentifierCredit2              = PRODUCT_IDENTIFIER_BASE CREDIT @"2";
NSString* const  PurchaseManagerProductIdentifierCredit5              = PRODUCT_IDENTIFIER_BASE CREDIT @"5";
NSString* const  PurchaseManagerProductIdentifierCredit10             = PRODUCT_IDENTIFIER_BASE CREDIT @"10";
NSString* const  PurchaseManagerProductIdentifierCredit20             = PRODUCT_IDENTIFIER_BASE CREDIT @"20";
NSString* const  PurchaseManagerProductIdentifierCredit50             = PRODUCT_IDENTIFIER_BASE CREDIT @"50";
 

@interface PurchaseManager () <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (nonatomic, strong) NSSet*                productIdentifiers;
@property (nonatomic, strong) SKProductsRequest*    productsRequest;
@property (nonatomic, copy) void (^accountCompletion)(BOOL success, id object);
@property (nonatomic, copy) void (^loadCompletion)(BOOL success);
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
                                            PurchaseManagerProductIdentifierNumberSetup1,
                                            PurchaseManagerProductIdentifierNumberSetup2,
                                            PurchaseManagerProductIdentifierNumberSetup3,
                                            PurchaseManagerProductIdentifierNumberSetup4,
                                            PurchaseManagerProductIdentifierNumberSetup5,
                                            PurchaseManagerProductIdentifierNumberSetup6,
                                            PurchaseManagerProductIdentifierNumberSetup7,
                                            PurchaseManagerProductIdentifierNumberSetup8,
                                            PurchaseManagerProductIdentifierNumberSetup9,
                                            PurchaseManagerProductIdentifierNumberSetup10,
                                            PurchaseManagerProductIdentifierNumberSetup11,
                                            PurchaseManagerProductIdentifierNumberSetup12,
                                            PurchaseManagerProductIdentifierNumberSetup13,
                                            PurchaseManagerProductIdentifierNumberSetup14,
                                            PurchaseManagerProductIdentifierNumberSetup15,
                                            PurchaseManagerProductIdentifierNumberSetup16,
                                            PurchaseManagerProductIdentifierNumberSetup17,
                                            PurchaseManagerProductIdentifierNumberSetup18,
                                            PurchaseManagerProductIdentifierNumberSetup19,
                                            PurchaseManagerProductIdentifierNumberSetup20,
                                            PurchaseManagerProductIdentifierNumberSubscription1,
                                            PurchaseManagerProductIdentifierNumberSubscription2,
                                            PurchaseManagerProductIdentifierNumberSubscription3,
                                            PurchaseManagerProductIdentifierNumberSubscription4,
                                            PurchaseManagerProductIdentifierNumberSubscription5,
                                            PurchaseManagerProductIdentifierNumberSubscription6,
                                            PurchaseManagerProductIdentifierNumberSubscription7,
                                            PurchaseManagerProductIdentifierNumberSubscription8,
                                            PurchaseManagerProductIdentifierNumberSubscription9,
                                            PurchaseManagerProductIdentifierNumberSubscription10,
                                            PurchaseManagerProductIdentifierNumberSubscription11,
                                            PurchaseManagerProductIdentifierNumberSubscription12,
                                            PurchaseManagerProductIdentifierNumberSubscription13,
                                            PurchaseManagerProductIdentifierNumberSubscription14,
                                            PurchaseManagerProductIdentifierNumberSubscription15,
                                            PurchaseManagerProductIdentifierNumberSubscription16,
                                            PurchaseManagerProductIdentifierNumberSubscription17,
                                            PurchaseManagerProductIdentifierNumberSubscription18,
                                            PurchaseManagerProductIdentifierNumberSubscription19,
                                            PurchaseManagerProductIdentifierNumberSubscription20,
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
                [sharedManager loadProducts:nil];
            }

            if (sharedManager.products != nil)
            {
                // At subsequent time the app get connected to internet,
                // and when products loaded & transactions restored at earlier time.
                [[NSNotificationCenter defaultCenter] removeObserver:observer];
            }
        }];
    }

    sharedManager->_currencyCode = [Settings sharedSettings].currencyCode;
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
    return ([productIdentifier rangeOfString:ACCOUNT].location != NSNotFound);
}


- (BOOL)isNumberSetupProductIdentifier:(NSString*)productIdentifier
{
    return ([productIdentifier rangeOfString:NUMBER_SETUP].location != NSNotFound);
}


- (BOOL)isNumberSubscriptionProductIdentifier:(NSString*)productIdentifier
{
    return ([productIdentifier rangeOfString:NUMBER_SUBSCRIPTION].location != NSNotFound);
}


- (BOOL)isCreditProductIdentifier:(NSString*)productIdentifier
{
    return ([productIdentifier rangeOfString:CREDIT].location != NSNotFound);
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
    self.products = response.products;
    
    for (SKProduct* product in self.products)
    {
        if ([self isCreditProductIdentifier:product.productIdentifier])
        {
            _currencyCode = [product.priceLocale objectForKey:NSLocaleCurrencyCode];
            [Settings sharedSettings].currencyCode = _currencyCode;
            break;
        }
    }

    [Common enableNetworkActivityIndicator:NO];
    self.loadCompletion ? self.loadCompletion(YES) : 0;
    self.loadCompletion = nil;
    self.productsRequest = nil;
}


- (void)request:(SKRequest*)request didFailWithError:(NSError*)error
{
    NSString*   title;
    NSString*   message;

    title = NSLocalizedStringWithDefaultValue(@"Purchase:General ProductLoadFailAlertTitle", nil,
                                              [NSBundle mainBundle], @"Loading Products Failed",
                                              @"Alert title telling in-app purchases are disabled.\n"
                                              @"[iOS alert title size - abbreviated: 'Can't Pay'].");
    message = NSLocalizedStringWithDefaultValue(@"Purchase:General ProductLoadFailAlertMessage", nil,
                                                [NSBundle mainBundle],
                                                @"Loading iTunes Store products failed: %@.\nPlease try again later.",
                                                @"Alert message: Information could not be loaded over internet.\n"
                                                @"[iOS alert message size]");
    if (error != nil)
    {
        message = [NSString stringWithFormat:message, [error localizedDescription]];
    }
    else
    {
        NSString*   description = NSLocalizedStringWithDefaultValue(@"Purchase:General NoInternet", nil,
                                                                    [NSBundle mainBundle],
                                                                    @"There is no internet connection",
                                                                    @"Short text that is part of alert message.\n"
                                                                    @"[Keep short]");
        message = [NSString stringWithFormat:message, description];
    }
    
    [BlockAlertView showAlertViewWithTitle:title
                                   message:message
                                completion:^(BOOL cancelled, NSInteger buttonIndex)
    {
        [Common enableNetworkActivityIndicator:NO];
        self.loadCompletion ? self.loadCompletion(NO) : 0;
        self.loadCompletion = nil;
        self.productsRequest = nil;
    }
                         cancelButtonTitle:[CommonStrings closeString]
                         otherButtonTitles:nil];

    NSLog(@"//### Failed to load list of products.");
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
        else if ([self isNumberSubscriptionProductIdentifier:transaction.payment.productIdentifier])
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
    else
    {
        if (self.accountCompletion != nil)
        {
            self.accountCompletion(YES, nil);
        }

        self.accountCompletion    = nil;
        self.restoredTransactions = nil;
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
                            // Dummy block.
                        };
                    }

                    [self processAccountTransaction:transaction];
                }
                else if ([self isNumberSetupProductIdentifier:transaction.payment.productIdentifier])
                {
                    [self purchaseManager:self processNumberTransaction:transaction];
                }
                else if ([self isNumberSubscriptionProductIdentifier:transaction.payment.productIdentifier])
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

- (void)loadProducts:(void (^)(BOOL success))completion
{
    if (self.productsRequest == nil)
    {
        self.loadCompletion = completion;

        self.productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:self.productIdentifiers];
        self.productsRequest.delegate = self;
        [self.productsRequest start];

        [Common enableNetworkActivityIndicator:YES];
    }
}


- (NSString*)productIdentifierForNumberTier:(int)tier
{
    NSString*   identifier = [NSString stringWithFormat: PRODUCT_IDENTIFIER_BASE @"Number%d", tier];

    return [self getProductForProductIdentifier:identifier].productIdentifier;
}


- (NSString*)localizedFormattedPrice:(float)price
{
    NSString*   formattedString;

    if (self.products != nil || _currencyCode.length > 0)
    {
        NSNumberFormatter*  numberFormatter;

        numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [numberFormatter setLocale:((SKProduct*)self.products[0]).priceLocale];

        formattedString = [numberFormatter stringFromNumber:@(price)];
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


- (void)buyAccount:(void (^)(BOOL success, id object))completion
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

    self.accountCompletion = completion;

    [[PurchaseManager sharedManager] buyProductIdentifier:PurchaseManagerProductIdentifierAccount];
}


- (void)restoreAccount:(void (^)(BOOL success, id object))completion
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
