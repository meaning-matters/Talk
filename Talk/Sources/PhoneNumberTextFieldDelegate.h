//
//  PhoneNumberTextFieldDelegate.h
//  Talk
//
//  Created by Cornelis van der Bent on 03/08/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PhoneNumber.h"


@interface PhoneNumberTextFieldDelegate : NSObject <UITextFieldDelegate>

@property (nonatomic, strong) PhoneNumber*  phoneNumber;
@property (nonatomic, strong) UITextField*  textField;


- (instancetype)initWithTextField:(UITextField*)textField;

@end
