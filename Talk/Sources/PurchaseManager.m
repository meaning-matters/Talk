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
#import "CallManager.h"


// These must match perfectly to what's in iTunesConnect.
#define PRODUCT_IDENTIFIER_BASE @"com.numberbay."
#define ACCOUNT                 @"Account"
#define CREDIT                  @"Credit"
#define NUMBER                  @"Number"
#define LOAD_PRODUCTS_INTERVAL  3600


@interface PurchaseManager () <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (nonatomic, strong) NSMutableSet*         productIdentifiers;
@property (atomic, strong) SKProductsRequest*       productsRequest;
@property (nonatomic, copy) void (^accountCompletion)(BOOL success, id object);
@property (nonatomic, copy) void (^loadCompletion)(BOOL success);
@property (nonatomic, strong) NSMutableArray*       restoredTransactions;
@property (nonatomic, strong) NSDate*               loadProductsDate;

@end


@implementation PurchaseManager

@synthesize currencyCode = _currencyCode;
@synthesize isNewAccount = _isNewAccount;

#pragma mark - Singleton Stuff

+ (PurchaseManager*)sharedManager
{
    static PurchaseManager* sharedInstance;
    static dispatch_once_t  onceToken;

    dispatch_once(&onceToken, ^
    {
        sharedInstance = [[PurchaseManager alloc] init];

        sharedInstance.productIdentifiers = [NSMutableSet set];
        [sharedInstance addProductIdentifiers];

        [[SKPaymentQueue defaultQueue] addTransactionObserver:sharedInstance];

        // Load the products each time the app starts.
        __block id  observer;
        observer = [[NSNotificationCenter defaultCenter] addObserverForName:NetworkStatusReachableNotification
                                                                     object:nil
                                                                      queue:[NSOperationQueue mainQueue]
                                                                 usingBlock:^(NSNotification* notification)
        {
            NetworkStatusReachable reachable = [notification.userInfo[@"status"] intValue];

            if (reachable == NetworkStatusReachableWifi || reachable == NetworkStatusReachableCellular)
            {
                // At first time the app gets connected to internet.
                [sharedInstance loadProducts:nil];
            }

            if (sharedInstance.products != nil)
            {
                // At subsequent time the app get connected to internet,
                // and when products loaded & transactions restored at earlier time.
                [[NSNotificationCenter defaultCenter] removeObserver:observer];
            }
        }];

        sharedInstance->_currencyCode = [Settings sharedSettings].currencyCode;
    });

    return sharedInstance;
}


- (void)addProductIdentifiers
{
    [self.productIdentifiers addObject:[self productIdentifierForAccountTier:1]];

    [self.productIdentifiers addObject:[self productIdentifierForCreditTier: 1]];
    [self.productIdentifiers addObject:[self productIdentifierForCreditTier: 2]];
    [self.productIdentifiers addObject:[self productIdentifierForCreditTier: 5]];
    [self.productIdentifiers addObject:[self productIdentifierForCreditTier:10]];
    [self.productIdentifiers addObject:[self productIdentifierForCreditTier:20]];
    [self.productIdentifiers addObject:[self productIdentifierForCreditTier:50]];

    for (int tier = 1; tier <= 80; tier++)
    {
        [self.productIdentifiers addObject:[self productIdentifierForNumberTier:tier]];
    }
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


- (BOOL)isCreditProductIdentifier:(NSString*)productIdentifier
{
    return ([productIdentifier rangeOfString:CREDIT].location != NSNotFound);
}


- (BOOL)isNumberProductIdentifier:(NSString*)productIdentifier
{
    return ([productIdentifier rangeOfString:NUMBER].location != NSNotFound);
}


#pragma mark - Transaction Processing

- (void)processAccountTransaction:(SKPaymentTransaction*)transaction
{
    NSMutableDictionary*    parameters = [NSMutableDictionary dictionary];
    parameters[@"receipt"] = [Base64 encode:transaction.transactionReceipt];

    [[WebClient sharedClient] retrieveWebAccount:parameters
                                           reply:^(WebClientStatus status, id content)
    {
        if (status == WebClientStatusOk)
        {
            [Settings sharedSettings].webUsername  = ((NSDictionary*)content)[@"username"];
            [Settings sharedSettings].webPassword  = ((NSDictionary*)content)[@"password"];
            [Settings sharedSettings].verifiedE164 = ((NSDictionary*)content)[@"e164"];

            NSMutableDictionary*  parameters = [NSMutableDictionary dictionary];
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
                    if (self.accountCompletion != nil)
                    {
                        NSString* description = NSLocalizedStringWithDefaultValue(@"Purchase:General SipAccountFailed", nil,
                                                                                  [NSBundle mainBundle], @"Could not get VoIP account",
                                                                                  @"Error message ...\n"
                                                                                  @"[...].");
                        NSError*  error       = [Common errorWithCode:0 description:description];

                        self.accountCompletion(NO, error);
                        self.accountCompletion = nil;
                    }
                    else
                    {
                        NSLog(@"//### accountCompletion == nil");
#warning Sometimes get here when two different accounts failed and Store retrieves them both at app start.
                    }
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
            NSString* description = NSLocalizedStringWithDefaultValue(@"Purchase:General WebAccountFailed", nil,
                                                                      [NSBundle mainBundle], @"Could not get web account",
                                                                      @"Error message ...\n"
                                                                      @"[...].");
            NSError*        error = [Common errorWithCode:0 description:description];
            self.accountCompletion(NO, error);
            self.accountCompletion = nil;
        }
    }];
}


- (void)processNumberTransaction:(SKPaymentTransaction*)transaction
{
    NSString*   receipt = [Base64 encode:transaction.transactionReceipt];
    NSLog(@"number receipt: %@", receipt);

    [self finishTransaction:transaction];
}


- (void)processCreditTransaction:(SKPaymentTransaction*)transaction
{
    NSString*   receipt = [Base64 encode:transaction.transactionReceipt];
    NSLog(@"credit receipt: %@", receipt);

    [self finishTransaction:transaction];
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
    self.loadProductsDate = [NSDate date];
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
        if (transaction.originalTransaction != nil)
        {
            if ([self isAccountProductIdentifier:transaction.originalTransaction.payment.productIdentifier])
            {
                // A new account: up to 1 day old.
                _isNewAccount = (-[transaction.originalTransaction.transactionDate timeIntervalSinceNow] < (24 * 3600));
            }
        }

        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"//### Busy purchasing");
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
                else if ([self isNumberProductIdentifier:transaction.payment.productIdentifier])
                {
                    [self processNumberTransaction:transaction];
                }
                else if ([self isCreditProductIdentifier:transaction.payment.productIdentifier])
                {
                    [self processCreditTransaction:transaction];
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
                else
                {
                    NSLog(@"Transaction failed: %@", [transaction.error localizedDescription]);
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


- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray*)transactions
{
    for (SKPaymentTransaction* transaction in transactions)
    {
        [self finishTransaction:transaction];
    }
}


#pragma mark - Public API

- (void)loadProducts:(void (^)(BOOL success))completion
{
    if ((self.loadProductsDate == nil || -[self.loadProductsDate timeIntervalSinceNow] > LOAD_PRODUCTS_INTERVAL) &&
        self.productsRequest == nil)
    {
        self.loadCompletion = completion;

        self.productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:self.productIdentifiers];
        self.productsRequest.delegate = self;
        [self.productsRequest start];

        [Common enableNetworkActivityIndicator:YES];
    }
    else if (self.productsRequest != nil && self.loadCompletion == nil)
    {
        // The NetworkStatusReachableNotification was fired (when we don't set completion),
        // and we're busy loading.  But any other (making this second invocation, e.g.
        // ProvisioningViewController) does wants to get feedback when done, so we assign
        // that here.
        self.loadCompletion = completion;
    }
    else
    {
        completion ? completion(YES) : 0;
    }
}


- (NSString*)productIdentifierForAccountTier:(int)tier
{
    return [NSString stringWithFormat:PRODUCT_IDENTIFIER_BASE ACCOUNT @"%d", tier];
}


- (NSString*)productIdentifierForCreditTier:(int)tier
{
    return [NSString stringWithFormat:PRODUCT_IDENTIFIER_BASE CREDIT @"%d", tier];
}


- (NSString*)productIdentifierForNumberTier:(int)tier
{
    return [NSString stringWithFormat:PRODUCT_IDENTIFIER_BASE NUMBER @"%d", tier];
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

    [self buyProductIdentifier:[self productIdentifierForAccountTier:1]];
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
