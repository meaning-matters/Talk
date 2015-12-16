//
//  ProofType.m
//  Talk
//
//  Created by Cornelis van der Bent on 16/12/15.
//  Copyright © 2015 NumberBay Ltd. All rights reserved.
//

#import "ProofType.h"

@implementation ProofType

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
