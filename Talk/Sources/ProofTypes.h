//
//  ProofTypes.h
//  Talk
//
//  Created by Cornelis van der Bent on 16/12/15.
//  Copyright © 2015 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Salutation.h"


@interface ProofTypes : NSObject

@property (nonatomic, readonly) NSString* localizedAddressProofsString;
@property (nonatomic, readonly) NSString* localizedIdentityProofsString;

@property (nonatomic, readonly) BOOL      requiresAddressProof;
@property (nonatomic, readonly) BOOL      requiresIdentityProof;


- (instancetype)initWithPerson:(NSDictionary*)person company:(NSDictionary*)company salutation:(Salutation*)salutation;

@end
