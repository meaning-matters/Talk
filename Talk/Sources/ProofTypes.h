//
//  ProofTypes.h
//  Talk
//
//  Created by Cornelis van der Bent on 16/12/15.
//  Copyright © 2015 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Salutation.h"

// Due to Voxbone issue described in our ticket https://support.voxbone.com/hc/en-us/requests/141059 France and Turkey
// mobile Numbers need an identity proof, but the proof image must be delivered in the address proof field.
//
// To temprarily support this from the app, we changed the server Regulation table. It now allows mixing the key (either
// "addressProofTypes" or "identityProofTypes") and the actual proof type identifiers ("UTILITY", "ID_CARD", "PASSPORT",
// and "COMPANY"). For France we now have {"addressProofType" : ["ID_CARD", "PASSPORT"]}, which says we need an address
// proof, but then asks for either an ID card or paspoort image; a mix of both.
//
// By introducing requiresAddressProofType and requiresIdentityProofType, the AddressViewController can now deal with
// proof types that are mixed.
//
// This change was committed SAT 10 JUN 2017 around 15:45.

@interface ProofTypes : NSObject

@property (nonatomic, readonly) NSString* localizedAddressProofsString;
@property (nonatomic, readonly) NSString* localizedIdentityProofsString;

@property (nonatomic, readonly) BOOL      requiresAddressProof;
@property (nonatomic, readonly) BOOL      requiresIdentityProof;

@property (nonatomic, readonly) BOOL      requiresAddressProofType;
@property (nonatomic, readonly) BOOL      requiresIdentityProofType;

- (instancetype)initWithPerson:(NSDictionary*)person company:(NSDictionary*)company salutation:(Salutation*)salutation;

@end
