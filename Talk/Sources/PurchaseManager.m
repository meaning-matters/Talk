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
@property (nonatomic, copy) void (^completion)(BOOL success, NSArray* transactions);
@property (nonatomic, strong) NSMutableArray*       restoredTransactions;

@end


@implementation PurchaseManager

@synthesize delegate             = _delegate;
@synthesize products             = _products;
@synthesize currencyRate         = _currencyRate;
@synthesize productIdentifiers   = _productIdentifiers;
@synthesize productsRequest      = _productsRequest;
@synthesize completion           = _completion;
@synthesize restoredTransactions = _restoredTransactions;


static PurchaseManager*     sharedManager;


#pragma mark - Singleton Stuff

+ (void)initialize
{
    if ([PurchaseManager class] == self)
    {
        sharedManager = [self new];

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
            NetworkStatusReachable reachable = [[note.userInfo objectForKey:@"status"] intValue];

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
                // At subsequent time the app get connected to internet, and when products were loaded at earlier time.
                [[NSNotificationCenter defaultCenter] removeObserver:observer];
            }
        }];

        sharedManager.restoredTransactions = [NSMutableArray array];
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
        NSRange range = [product.productIdentifier rangeOfString:@"Credit"];
        if (range.location != NSNotFound)
        {
            NSUInteger  index = range.location + range.length;
            float       usdPrice = [[product.productIdentifier substringFromIndex:index] floatValue] - 0.01f;
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
    self.completion(YES, self.restoredTransactions);

    for (SKPaymentTransaction* transaction in self.restoredTransactions)
    {
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    }

    [self.restoredTransactions removeAllObjects];
    self.completion = nil;
}


- (void)paymentQueue:(SKPaymentQueue*)queue restoreCompletedTransactionsFailedWithError:(NSError*)error
{
    NSLog(@"paymentQueueRestoreCompletedTransactionsFinished");
    self.completion(NO, nil);
}


- (void)paymentQueue:(SKPaymentQueue*)queue updatedTransactions:(NSArray*)transactions
{
    for (SKPaymentTransaction* transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchasing:
                break;

            case SKPaymentTransactionStatePurchased:
                break;

            case SKPaymentTransactionStateFailed:
                break;

            case SKPaymentTransactionStateRestored:
                [self.restoredTransactions addObject:transactions];
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


- (void)restoreCompletedTransactions:(void (^)(BOOL success, NSArray* transactions))completion;
{
    self.completion = completion;

    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

@end
