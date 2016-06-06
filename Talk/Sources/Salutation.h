//
//  Salutation.h
//  Talk
//
//  Created by Cornelis van der Bent on 01/02/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SalutationValue)
{
    SalutationValueMs      = 1,
    SalutationValueMr      = 2,
    SalutationValueCompany = 3,
};


@interface Salutation : NSObject

@property (nonatomic, assign) SalutationValue value;
@property (nonatomic, readonly) NSString*     string;
@property (nonatomic, readonly) NSString*     localizedString;
@property (nonatomic, readonly) BOOL          isPerson;
@property (nonatomic, readonly) BOOL          isCompany;
@property (nonatomic, readonly) NSString*     typeString;   // Either "person" or "company".

- (instancetype)initWithString:(NSString*)string;

- (instancetype)initWithValue:(SalutationValue)value;

+ (NSString*)localizedStringForValue:(SalutationValue)value;

@end
