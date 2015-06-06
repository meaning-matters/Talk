    //
//  PurchaseManager.m
//  Talk
//
//  Created by Cornelis van der Bent on 24/01/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "PurchaseManager.h"
#import "NetworkStatus.h"
#import "Common.h"
#import "Strings.h"
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
@property (nonatomic, copy) void (^buyCompletion)(BOOL success, id object);
@property (nonatomic, copy) void (^loadCompletion)(BOOL success);
@property (nonatomic, strong) SKPaymentTransaction* restoredAccountTransaction;
@property (nonatomic, strong) NSDate*               loadProductsDate;

@end


@implementation PurchaseManager

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

    [self.productIdentifiers addObject:[self productIdentifierForCreditTier: 1]];   //   1 amount.
    [self.productIdentifiers addObject:[self productIdentifierForCreditTier: 2]];   //   2 amounts.
    [self.productIdentifiers addObject:[self productIdentifierForCreditTier: 5]];   //   5 amounts.
    [self.productIdentifiers addObject:[self productIdentifierForCreditTier:10]];   //  10 amounts.
    [self.productIdentifiers addObject:[self productIdentifierForCreditTier:20]];   //  20 amounts.
    [self.productIdentifiers addObject:[self productIdentifierForCreditTier:50]];   //  50 amounts.
    [self.productIdentifiers addObject:[self productIdentifierForCreditTier:60]];   // 100 amounts.
    [self.productIdentifiers addObject:[self productIdentifierForCreditTier:72]];   // 200 amounts.
}


#pragma mark - Helper Methods

- (SKProduct*)productForProductIdentifier:(NSString*)productIdentifier
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


- (void)completeBuyWithSuccess:(BOOL)success object:(id)object
{
    if (self.buyCompletion != nil)
    {
        self.buyCompletion(success, object);
        self.buyCompletion = nil;
    }
    else if (success == YES)
    {
        SKPaymentTransaction* transaction = object;

        if ([self isCreditProductIdentifier:transaction.payment.productIdentifier])
        {
            NSString* title;
            NSString* message;

            title   = NSLocalizedStringWithDefaultValue(@"Purchase:Retry CreditTitle", nil,
                                                        [NSBundle mainBundle], @"Credit Purchase Done",
                                                        @".\n"
                                                        @"[iOS alert title size - abbreviated: 'Can't Pay'].");
            message = NSLocalizedStringWithDefaultValue(@"Purchase:Retry CreditMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Your pending credit purchase (%@) was fully processed. "
                                                        @"(Notice that the current credit may already have been "
                                                        @"increased earlier for this purchase.)\n\n"
                                                        @"You can now continue buying other credit amounts.",
                                                        @".\n"
                                                        @"[iOS alert title size - abbreviated: 'Can't Pay'].");
            NSString* priceString = [self localizedPriceForProductIdentifier:transaction.payment.productIdentifier];
            message = [NSString stringWithFormat:message, priceString];
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:nil
                                 cancelButtonTitle:[Strings closeString]
                                 otherButtonTitles:nil];
        }
    }
}


- (void)buyProductIdentifier:(NSString*)productIdentifier completion:(void (^)(BOOL success, id object))completion
{
    if ([SKPaymentQueue defaultQueue].transactions.count > 0)
    {
        if ([self retryPendingTransactions] == YES)
        {
            completion(NO, nil);

            return;
        }
    }

    self.buyCompletion = completion;

    if ([SKPaymentQueue canMakePayments])
    {
        SKProduct* product = [self productForProductIdentifier:productIdentifier];

        if (product != nil)
        {
            SKPayment*  payment = [SKPayment paymentWithProduct:product];
            [[SKPaymentQueue defaultQueue] addPayment:payment];
            [Common enableNetworkActivityIndicator:YES];

            // return YES;//### replace with completion() further up.
        }
        else
        {
            NSString* title;
            NSString* message;

            title   = NSLocalizedStringWithDefaultValue(@"Purchase:General NoProductTitle", nil,
                                                        [NSBundle mainBundle], @"Product Not Available",
                                                        @"Alert title telling in-app purchases are disabled.\n"
                                                        @"[iOS alert title size - abbreviated: 'Can't Pay'].");
            message = NSLocalizedStringWithDefaultValue(@"Purchase:General NoProductMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"The product you're trying to buy is not available, or "
                                                        @"was not loaded.\n\nPlease try again later.",
                                                        @"Message telling that product was not found.\n"
                                                        @"[iOS alert title size - abbreviated: 'Can't Pay'].");
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:nil
                                 cancelButtonTitle:[Strings closeString]
                                 otherButtonTitles:nil];

            [self completeBuyWithSuccess:NO object:nil];
        }
    }
    else
    {
        NSString* title;
        NSString* message;

        title   = NSLocalizedStringWithDefaultValue(@"Purchase:General CantPurchaseTitle", nil,
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
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];

        [self completeBuyWithSuccess:NO object:nil];
    }
}


- (void)finishTransaction:(SKPaymentTransaction*)transaction
{
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}


- (NSLocale*)priceLocale
{
    if (self.products.count > 0)
    {
        return ((SKProduct*)self.products[0]).priceLocale;
    }
    else
    {
        NSDictionary* localeInfo = @{NSLocaleCurrencyCode : self.currencyCode,
                                     NSLocaleLanguageCode : [[NSLocale preferredLanguages] objectAtIndex:0]};

        return [[NSLocale alloc] initWithLocaleIdentifier:[NSLocale localeIdentifierFromComponents:localeInfo]];
    }

}


#pragma mark - Transaction Processing

- (void)processAccountTransaction:(SKPaymentTransaction*)transaction
{
    // I tried [NSBundle appStoreReceiptURL] ..., but this requires server-side changes.
    [[WebClient sharedClient] retrieveAccountsForReceipt:[Base64 encode:transaction.transactionReceipt]
                                                language:[[NSLocale preferredLanguages] objectAtIndex:0]
                                       notificationToken:[AppDelegate appDelegate].deviceToken
                                       mobileCountryCode:[NetworkStatus sharedStatus].simMobileCountryCode
                                       mobileNetworkCode:[NetworkStatus sharedStatus].simMobileNetworkCode
                                                   reply:^(NSError*  error,
                                                           NSString* webUsername,
                                                           NSString* webPassword,
                                                           NSString* sipUsername,
                                                           NSString* sipPassword,
                                                           NSString* sipRealm)
    {
        if (error == nil)
        {
            [Settings sharedSettings].webUsername = webUsername;
            [Settings sharedSettings].webPassword = webPassword;

            [self finishTransaction:transaction];
            [self completeBuyWithSuccess:YES object:transaction];
        }
        else
        {
            // If this was a restored transaction, it already been 'finished' in updatedTransactions:.
            NSString* description = NSLocalizedStringWithDefaultValue(@"Purchase:General WebAccountFailed", nil,
                                                                      [NSBundle mainBundle], @"Could not get account",
                                                                      @"Error message ...\n"
                                                                      @"[...].");
            [self completeBuyWithSuccess:NO object:[Common errorWithCode:error.code description:description]];
        }
    }];
}


- (void)processCreditTransaction:(SKPaymentTransaction*)transaction
{
    // Return when products are not yet loaded.  This method might namely be
    // called early when a transaction was pending.
    if (_products == nil)
    {
        return;
    }

    NSString* receipt = [Base64 encode:transaction.transactionReceipt];

    [[WebClient sharedClient] purchaseCreditForReceipt:receipt
                                          currencyCode:self.currencyCode
                                                 reply:^(NSError* error, float credit)
    {
        if (error == nil)
        {
            [self finishTransaction:transaction];
            [Settings sharedSettings].credit = credit;
            [self completeBuyWithSuccess:YES object:transaction];
        }
        else
        {
            NSString* description = NSLocalizedStringWithDefaultValue(@"Purchase:General ProcessCreditFailed", nil,
                                                                      [NSBundle mainBundle],
                                                                      @"Could not fully process credit; "
                                                                      @"this will be retried when credit is refreshed, "
                                                                      @"or when you try to buy credit",
                                                                      @"Error message ...\n"
                                                                      @"[...].");
            [self completeBuyWithSuccess:NO object:[Common errorWithCode:error.code description:description]];
        }
    }];
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
    self.loadProductsDate = [NSDate date];
    self.productsRequest  = nil;

    self.loadCompletion ? self.loadCompletion(YES) : 0;
    self.loadCompletion   = nil;
}


- (void)request:(SKRequest*)request didFailWithError:(NSError*)error
{
    NSString* title;
    NSString* message;

    title   = NSLocalizedStringWithDefaultValue(@"Purchase:General ProductLoadFailAlertTitle", nil,
                                                [NSBundle mainBundle], @"Loading Products Failed",
                                                @"Alert title telling in-app purchases are disabled.\n"
                                                @"[iOS alert title size - abbreviated: 'Can't Pay'].");
    message = NSLocalizedStringWithDefaultValue(@"Purchase:General ProductLoadFailAlertMessage", nil,
                                                [NSBundle mainBundle],
                                                @"Loading iTunes Store products failed: %@\n\nPlease try again later.",
                                                @"Alert message: Information could not be loaded over internet.\n"
                                                @"[iOS alert message size]");
    if (error != nil && error.code != 0)
    {
        message = [NSString stringWithFormat:message, error.localizedDescription];
    }
    else
    {
        NSString* description = NSLocalizedStringWithDefaultValue(@"Purchase:General NoInternet", nil,
                                                                  [NSBundle mainBundle],
                                                                  @"There is no internet connection.",
                                                                  @"Short text that is part of alert message.\n"
                                                                  @"[Keep short]");
        message = [NSString stringWithFormat:message, description];
    }
    
    [BlockAlertView showAlertViewWithTitle:title
                                   message:message
                                completion:^(BOOL cancelled, NSInteger buttonIndex)
    {
        [Common enableNetworkActivityIndicator:NO];
        self.productsRequest = nil;

        self.loadCompletion ? self.loadCompletion(NO) : 0;
        self.loadCompletion  = nil;
    }
                         cancelButtonTitle:[Strings closeString]
                         otherButtonTitles:nil];

    // Force a load.
    self.loadProductsDate = nil;
}


#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue*)queue
{
    NBLog(@"paymentQueueRestoreCompletedTransactionsFinished");
    [Common enableNetworkActivityIndicator:NO];

    if (self.restoredAccountTransaction != nil)
    {
        if ([self isAccountProductIdentifier:self.restoredAccountTransaction.payment.productIdentifier])
        {
            [self processAccountTransaction:self.restoredAccountTransaction];
        }
        else
        {
            NBLog(@"//### Unexpected restored transaction: %@.", self.restoredAccountTransaction.payment.productIdentifier);
        }
    }
    else
    {
        [self completeBuyWithSuccess:YES object:nil];
        self.restoredAccountTransaction = nil;
    }
}


- (void)paymentQueue:(SKPaymentQueue*)queue restoreCompletedTransactionsFailedWithError:(NSError*)error
{
    NBLog(@"restoreCompletedTransactionsFailedWithError: %@", error.localizedDescription);
    [Common enableNetworkActivityIndicator:NO];

    [self completeBuyWithSuccess:NO object:error];
    self.restoredAccountTransaction = nil;
}


- (void)paymentQueue:(SKPaymentQueue*)queue updatedTransactions:(NSArray*)transactions
{
    for (SKPaymentTransaction* transaction in transactions)
    {
        if ([self isAccountProductIdentifier:transaction.payment.productIdentifier])
        {
            if (transaction.originalTransaction == nil)
            {
                _isNewAccount = YES;
            }
            else
            {
                // A new account: up to 1 day old.
                _isNewAccount = (-[transaction.originalTransaction.transactionDate timeIntervalSinceNow] < (24 * 3600));
            }
        }

        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchasing:
            {
                NBLog(@"//### Busy purchasing");
                break;
            }
            case SKPaymentTransactionStatePurchased:
            {
                [Common enableNetworkActivityIndicator:NO];
                if ([self isAccountProductIdentifier:transaction.payment.productIdentifier])
                {
                    [self processAccountTransaction:transaction];
                }
                else if ([self isCreditProductIdentifier:transaction.payment.productIdentifier])
                {
                    [self processCreditTransaction:transaction];
                }
                break;
            }
            case SKPaymentTransactionStateRestored:
            {
                [self finishTransaction:transaction];  // Finish multiple times is allowed.
                self.restoredAccountTransaction = transaction;
                break;
            }
            case SKPaymentTransactionStateFailed:
            {
                if (transaction.error.code == 2)
                {
                    NBLog(@"Did we see Already Purchased?");
                    [Common enableNetworkActivityIndicator:NO];
                    [self finishTransaction:transaction];
                    [self completeBuyWithSuccess:NO object:transaction.error];
                }
                else
                {
                    [Common enableNetworkActivityIndicator:NO];
                    [self finishTransaction:transaction];

                    NBLog(@"//### %@ transaction failed: %@ %d.", transaction.payment.productIdentifier,
                          [transaction.error localizedDescription],
                          (int)transaction.error.code);

                    [self completeBuyWithSuccess:NO object:transaction.error];
                }
                break;
            }
            SKPaymentTransactionStateDeferred:
            {
                // Waiting for user action (like tapping Buy).  We don't use this now.
                break;
            }
        }
    };
}


- (void)paymentQueue:(SKPaymentQueue*)queue updatedDownloads:(NSArray*)downloads
{
    // We don't have downloads.  (This method is required, that's the only reason it's here.)
}


#pragma mark - Public API

- (void)reset
{
    self.loadProductsDate = nil;    // Makes sure reload of products is done
}


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
        completion ? completion(self.currencyCode.length > 0) : 0;
    }
}


- (BOOL)retryPendingTransactions
{
    BOOL result = YES;

    for (SKPaymentTransaction* transaction in [SKPaymentQueue defaultQueue].transactions)
    {
        if ([self isCreditProductIdentifier:transaction.payment.productIdentifier])
        {
            [self processCreditTransaction:transaction];
        }
        else
        {
            result = NO;    // Indicates that caller must continue processing other (i.e., Account) transaction.
        }
    }

    return result;
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
    NSString* formattedString;
    NSLocale* priceLocale = [self priceLocale];

    if (priceLocale != nil)
    {
        NSNumberFormatter* numberFormatter;

        numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [numberFormatter setLocale:priceLocale];

        // Prevent -0.00 values when price is -0.004364 for example.
        double factor = pow(10, numberFormatter.maximumFractionDigits);
        price = round(price * factor) / factor;
        if (fpclassify(price) == FP_ZERO)
        {
            price = fabs(price);
        }

        formattedString = [numberFormatter stringFromNumber:@(price)];
    }
    else
    {
        formattedString = @"";
    }

    return formattedString;
}


- (NSString*)localizedFormattedPrice2ExtraDigits:(float)price
{
    NSString* formattedString;
    NSLocale* priceLocale = [self priceLocale];

    if (priceLocale != nil)
    {
        NSNumberFormatter* numberFormatter;

        numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [numberFormatter setLocale:priceLocale];

        NSUInteger fractionDigits = numberFormatter.maximumFractionDigits + 2;
        [numberFormatter setMaximumFractionDigits:fractionDigits];
        [numberFormatter setMinimumFractionDigits:fractionDigits];

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
    SKProduct* product = [self productForProductIdentifier:identifier];
    NSString*  priceString;

    if (product != nil)
    {
        NSNumberFormatter* numberFormatter;

        numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [numberFormatter setLocale:product.priceLocale];

        priceString = [numberFormatter stringFromNumber:product.price];
    }
    else
    {
        priceString = [NSString stringWithFormat:@"%d", [self amountOfProductIdentifier:identifier]];
    }

    return priceString;
}


- (void)buyAccount:(void (^)(BOOL success, id object))completion
{
    if (self.buyCompletion != nil)
    {
        completion ? completion(NO, nil) : 0;

        return;
    }

    [self buyProductIdentifier:[self productIdentifierForAccountTier:1] completion:completion];
}


- (void)restoreAccount:(void (^)(BOOL success, id object))completion
{
    if (self.buyCompletion != nil)
    {
        completion ? completion(NO, nil) : 0;

        return;
    }

    self.buyCompletion = completion;

    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    [Common enableNetworkActivityIndicator:YES];
}


- (void)buyCreditForTier:(int)tier completion:(void (^)(BOOL success, id object))completion
{
    if (self.buyCompletion != nil)
    {
        completion ? completion(NO, nil) : 0;

        return;
    }

    [self buyProductIdentifier:[self productIdentifierForCreditTier:tier] completion:completion];
}


- (void)buyNumberForMonths:(NSUInteger)months
                      name:(NSString*)name
            isoCountryCode:(NSString*)isoCountryCode
                  areaCode:(NSString*)areaCode
                  areaName:(NSString*)areaName
                 stateCode:(NSString*)stateCode
                 stateName:(NSString*)stateName
                numberType:(NSString*)numberType
                      info:(NSDictionary*)info
                completion:(void (^)(BOOL success, id object))completion
{
    [[WebClient sharedClient] purchaseNumberForMonths:months
                                                 name:name
                                       isoCountryCode:isoCountryCode
                                             areaCode:areaCode
                                             areaName:areaName
                                            stateCode:stateCode
                                            stateName:stateName
                                           numberType:numberType
                                                 info:info
                                                reply:^(NSError* error, NSString *e164)
    {
        if (error == nil)
        {
            completion ? completion(YES, nil) : 0;
        }
        else
        {
            completion ? completion(NO, error) : 0;
        }
    }];
}


- (int)tierForCredit:(float)credit
{
    NSArray* tierNumbers = @[ @(1), @(2), @(5), @(10), @(20), @(50), @(75) ];

    for (NSNumber* tierNumber in tierNumbers)
    {
        int        tier              = [tierNumber intValue];
        NSString*  productIdentifier = [self productIdentifierForCreditTier:tier];
        SKProduct* product           = [self productForProductIdentifier:productIdentifier];
        float      price             = [product.price floatValue];

        if (price > credit)
        {
            return tier;
        }
    }

    return 0;
}


- (int)tierOfProductIdentifier:(NSString*)identifier
{
    NSString*       tierString;
    NSScanner*      scanner = [NSScanner scannerWithString:identifier];
    NSCharacterSet* numbers = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];

    // Throw away characters before the tier number.
    [scanner scanUpToCharactersFromSet:numbers intoString:NULL];

    // Collect tier number.
    [scanner scanCharactersFromSet:numbers intoString:&tierString];

    return [tierString intValue];
}


- (int)amountOfProductIdentifier:(NSString*)identifier
{
    NSString*       tierString;
    int             tier;
    int             amount;
    NSScanner*      scanner = [NSScanner scannerWithString:identifier];
    NSCharacterSet* numbers = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];

    // Throw away characters before the tier number.
    [scanner scanUpToCharactersFromSet:numbers intoString:NULL];

    // Collect tier number.
    [scanner scanCharactersFromSet:numbers intoString:&tierString];

    tier = [tierString intValue];

    switch (tier)
    {
        case  0: amount =    0; break;
        case  1: amount =    1; break;
        case  2: amount =    2; break;
        case  5: amount =    5; break;
        case 10: amount =   10; break;
        case 20: amount =   20; break;
        case 50: amount =   50; break;
        case 60: amount =  100; break;
        case 72: amount =  200; break;
        case 82: amount =  500; break;
        case 87: amount = 1000; break;
    }

    return amount;
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

@end
