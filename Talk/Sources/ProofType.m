//
//  ProofType.m
//  Talk
//
//  Created by Cornelis van der Bent on 16/12/15.
//  Copyright © 2015 NumberBay Ltd. All rights reserved.
//

#import "ProofType.h"

typedef NS_ENUM(NSUInteger, ProofTypeMask)
{
    ProofTypeUtilityMask      = 1UL << 0,
    ProofTypeCompanyMask      = 1UL << 1,
    ProofTypePassportMask     = 1UL << 2,
    ProofTypeIdOrPassportMask = 1UL << 3,
};



@interface ProofType ()

@property (nonatomic, strong) NSDictionary* proofTypes;
@property (nonatomic, strong) Salutation*   salutation;

@end


@implementation ProofType

- (instancetype)initWithProofTypes:(NSDictionary*)proofTypes salutation:(Salutation*)salutation
{
    if (self = [super init])
    {
        _proofTypes = proofTypes;
        _salutation = salutation;
    }

    return self;
}


- (NSString*)localizedString
{
    NSString* key       = self.salutation.isPerson ? @"person" : @"company";
    NSString* proofType = self.proofTypes[key];
    NSString* string    = nil;

    if ([proofType isEqualToString:@"UTILITY"])
    {
        string = NSLocalizedStringWithDefaultValue(@"ProofType Utility", nil, [NSBundle mainBundle],
                                                   @"Utility Bill",
                                                   @"\n"
                                                   @"[One line].");
    }

    if ([proofType isEqualToString:@"COMPANY"])
    {
        string = NSLocalizedStringWithDefaultValue(@"ProofType Company", nil, [NSBundle mainBundle],
                                                   @"Company Registration",
                                                   @"\n"
                                                   @"[One line].");
    }

    if ([proofType isEqualToString:@"PASSPORT"])
    {
        string = NSLocalizedStringWithDefaultValue(@"ProofType Passport", nil, [NSBundle mainBundle],
                                                   @"Passport",
                                                   @"\n"
                                                   @"[One line].");
    }

    if ([proofType isEqualToString:@"ID_OR_PASSPORT"])
    {
        string = NSLocalizedStringWithDefaultValue(@"ProofType ID or Passport", nil, [NSBundle mainBundle],
                                                   @"Identity Card or Passport",
                                                   @"\n"
                                                   @"[One line].");
    }

    return string;
}


+ (NSString*)stringForProofTypeMask:(ProofTypeMask)mask
{
    switch (mask)
    {
        case ProofTypeUtilityMask:
        {
            return @"UTILITY";
        }
        case ProofTypeCompanyMask:
        {
            return @"COMPANY";
        }
        case ProofTypePassportMask:
        {
            return @"PASSPORT";
        }
        case ProofTypeIdOrPassportMask:
        {
            return @"ID_OR_PASSPORT";
        }
        default:
        {
            NBLog(@"Invalid AddressTypeMask.");
            return @"";
        }
    }
}


+ (ProofTypeMask)proofTypeMaskForString:(NSString*)string
{
    ProofTypeMask mask;
    
    if ([string isEqualToString:@"UTILITY"])
    {
        mask = ProofTypeUtilityMask;
    }
    else if ([string isEqualToString:@"COMPANY"])
    {
        mask = ProofTypeCompanyMask;
    }
    else if ([string isEqualToString:@"PASSPORT"])
    {
        mask = ProofTypePassportMask;
    }
    else if ([string isEqualToString:@"ID_OR_PASSPORT"])
    {
        mask = ProofTypeIdOrPassportMask;
    }
    else
    {
        mask = 0;   //### We should never get here.
    }
    
    return mask;
}

@end
