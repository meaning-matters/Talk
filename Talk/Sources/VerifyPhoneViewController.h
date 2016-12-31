//
//  VerifyPhoneViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 02/02/14.
//  Copyright (c) 2014 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class PhoneNumber;


@interface VerifyPhoneViewController : UIViewController

- (instancetype)initWithCompletion:(void (^)(PhoneNumber* verifiedPhoneNumber, NSString* uuid))completion;

@end
