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

// Delegate methods must call finishTransaction: when successful!
@protocol PurchaseManagerDelegate <NSObject>

- (void)purchaseManager:(PurchaseManager*)purchaseManager processNumberTransaction:(SKPaymentTransaction*)transaction;

- (void)purchaseManager:(PurchaseManager*)purchaseManager processCreditTransaction:(SKPaymentTransaction*)transaction;

@end


extern NSString* const  PurchaseManagerProductIdentifierAccount1;
extern NSString* const  PurchaseManagerProductIdentifierCredit1;
extern NSString* const  PurchaseManagerProductIdentifierCredit2;
extern NSString* const  PurchaseManagerProductIdentifierCredit5;
extern NSString* const  PurchaseManagerProductIdentifierCredit10;
extern NSString* const  PurchaseManagerProductIdentifierCredit20;
extern NSString* const  PurchaseManagerProductIdentifierCredit50;


@interface PurchaseManager : NSObject <PurchaseManagerDelegate>

@property (nonatomic, assign) id<PurchaseManagerDelegate>   delegate;
@property (nonatomic, strong) NSArray*                      products;
@property (nonatomic, readonly) NSString*                   currencyCode;   // Currency code (e.g. "USD" for current Store.


+ (PurchaseManager*)sharedManager;

- (void)loadProducts:(void (^)(BOOL success))completion;

- (NSString*)productIdentifierForCreditTier:(int)tier;

- (NSString*)productIdentifierForNumberTier:(int)tier;

- (NSString*)localizedFormattedPrice:(float)price;

- (NSString*)localizedPriceForProductIdentifier:(NSString*)identifier;

- (void)buyAccount:(void (^)(BOOL success, id object))completion;

- (void)restoreAccount:(void (^)(BOOL success, id object))completion;

- (BOOL)buyProductIdentifier:(NSString*)productIdentifier;

- (void)finishTransaction:(SKPaymentTransaction*)transaction;

@end
