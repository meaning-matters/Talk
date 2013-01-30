//
//  PurchaseManager.h
//  Talk
//
//  Created by Cornelis van der Bent on 24/01/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>


@class PurchaseManager;

@protocol PurchaseManagerDelegate <NSObject>

- (BOOL)purchaseManager:(PurchaseManager*)purchaseManager processAccountTransaction:(SKPaymentTransaction*)transaction;

- (BOOL)purchaseManager:(PurchaseManager*)purchaseManager processNumberTransaction:(SKPaymentTransaction*)transaction;

- (BOOL)purchaseManager:(PurchaseManager*)purchaseManager processCreditTransaction:(SKPaymentTransaction*)transaction;

- (BOOL)purchaseManager:(PurchaseManager*)purchaseManager restoreAccountTransaction:(SKPaymentTransaction*)transaction;

- (BOOL)purchaseManager:(PurchaseManager*)purchaseManager restoreNumberTransaction:(SKPaymentTransaction*)transaction;

@end


extern NSString* const  PurchaseManagerProductIdentifierAccount;
extern NSString* const  PurchaseManagerProductIdentifierNumber;
extern NSString* const  PurchaseManagerProductIdentifierCredit1;
extern NSString* const  PurchaseManagerProductIdentifierCredit2;
extern NSString* const  PurchaseManagerProductIdentifierCredit5;
extern NSString* const  PurchaseManagerProductIdentifierCredit10;
extern NSString* const  PurchaseManagerProductIdentifierCredit20;
extern NSString* const  PurchaseManagerProductIdentifierCredit50;


@interface PurchaseManager : NSObject

@property (nonatomic, assign) id<PurchaseManagerDelegate>   delegate;
@property (nonatomic, strong) NSArray*                      products;
@property (nonatomic, assign) float                         currencyRate;   // To convert credit from USD to local currency.


+ (PurchaseManager*)sharedManager;

- (NSString*)localizedFormattedPrice:(float)usdPrice;

- (void)restoreCompletedTransactions:(void (^)(BOOL success, NSArray* transactions))completion;

@end
