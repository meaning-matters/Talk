//
//  PurchaseManager.h
//  Talk
//
//  Created by Cornelis van der Bent on 24/01/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "NumberType.h"

extern NSString* const PurchaseManagerProductsLoadedNotification;


@interface PurchaseManager : NSObject

@property (nonatomic, strong) NSArray* products;
@property (nonatomic, readonly) BOOL   isNewAccount;     // YES, when is new account (i.e. not a restored account).


+ (PurchaseManager*)sharedManager;

- (void)reset;

- (void)loadProducts:(void (^)(BOOL success))completion;

- (BOOL)retryPendingTransactions;

- (NSString*)productIdentifierForCreditTier:(int)tier;

- (NSString*)productIdentifierForNumberTier:(int)tier;

- (NSString*)localizedFormattedPrice:(float)price;

- (NSString*)localizedFormattedPrice2ExtraDigits:(float)price;

- (NSString*)localizedPriceForProductIdentifier:(NSString*)identifier;

- (void)buyAccount:(void (^)(BOOL success, id object))completion;

- (void)restoreAccount:(void (^)(BOOL success, id object))completion;

- (void)buyCreditForTier:(int)tier completion:(void (^)(BOOL success, id object))completion;

- (int)tierForCredit:(float)credit;

- (int)tierOfProductIdentifier:(NSString*)identifier;

- (BOOL)isAccountProductIdentifier:(NSString*)productIdentifier;

- (BOOL)isCreditProductIdentifier:(NSString*)productIdentifier;

- (BOOL)isNumberProductIdentifier:(NSString*)productIdentifier;

@end
