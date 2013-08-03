//
//  PhoneNumberTextFieldDelegate.h
//  Talk
//
//  Created by Cornelis van der Bent on 03/08/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhoneNumber.h"


@interface PhoneNumberTextFieldDelegate : NSObject <UITextFieldDelegate>

@property (nonatomic, strong) PhoneNumber*  phoneNumber;
@property (nonatomic, strong) UITextField*  textField;


- (id)initWithTextField:(UITextField*)textField;

@end
