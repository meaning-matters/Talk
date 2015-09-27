//
//  VerifyPhoneViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 02/02/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PhoneNumber;


@interface VerifyPhoneViewController : UIViewController

- (instancetype)initWithCompletion:(void (^)(PhoneNumber* verifiedPhoneNumber))completion;

@end
