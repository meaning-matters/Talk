//
//  ProofImageViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 01/09/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AddressData.h"


typedef enum
{
    ProofImageTypeAddress  = 0,
    ProofImageTypeIdentity = 1,
} ProofImageType;

@interface ProofImageViewController : UIViewController

- (instancetype)initWithAddress:(AddressData*)address
                           type:(ProofImageType)type
                       editable:(BOOL)editable
                     completion:(void (^)(BOOL edited))completion;

@end
