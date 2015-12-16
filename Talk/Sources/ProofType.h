//
//  ProofType.h
//  Talk
//
//  Created by Cornelis van der Bent on 16/12/15.
//  Copyright © 2015 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ProofTypeMask)
{
    ProofTypeUtilityMask      = 1UL << 0,
    ProofTypeCompanyMask      = 1UL << 1,
    ProofTypePassportMask     = 1UL << 2,
    ProofTypeIdOrPassportMask = 1UL << 3,
};


@interface ProofType : NSObject

+ (NSString*)stringForProofTypeMask:(ProofTypeMask)mask;

+ (ProofTypeMask)proofTypeMaskForString:(NSString*)string;

@end
