//
//  PurchaseManager.h
//  Talk
//
//  Created by Cornelis van der Bent on 24/01/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString* const  PurchaseManagerProductIdentifierAccount;
extern NSString* const  PurchaseManagerProductIdentifierNumber;
extern NSString* const  PurchaseManagerProductIdentifierCredit1;
extern NSString* const  PurchaseManagerProductIdentifierCredit2;
extern NSString* const  PurchaseManagerProductIdentifierCredit5;
extern NSString* const  PurchaseManagerProductIdentifierCredit10;
extern NSString* const  PurchaseManagerProductIdentifierCredit20;
extern NSString* const  PurchaseManagerProductIdentifierCredit50;


@interface PurchaseManager : NSObject

@property (nonatomic, strong) NSArray*  products;
@property (nonatomic, assign) float     currencyRate;   // To convert credit from USD to local currency.


+ (PurchaseManager*)sharedManager;

- (NSString*)localizedFormattedPrice:(float)usdPrice;

@end
