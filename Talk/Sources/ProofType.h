//
//  ProofType.h
//  Talk
//
//  Created by Cornelis van der Bent on 16/12/15.
//  Copyright © 2015 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Salutation.h"


@interface ProofType : NSObject

@property (nonatomic, readonly) NSString* localizedString;

- (instancetype)initWithProofTypes:(NSDictionary*)proofTypes salutation:(Salutation*)salutation;

@end
