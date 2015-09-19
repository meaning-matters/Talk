//
//  PhoneNumberTextFieldDelegate.m
//  Talk
//
//  Created by Cornelis van der Bent on 03/08/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "PhoneNumberTextFieldDelegate.h"


@implementation PhoneNumberTextFieldDelegate

- (instancetype)initWithTextField:(UITextField*)textField
{
    if (self = [super init])
    {
        self.phoneNumber        = [[PhoneNumber alloc] init];
        self.phoneNumber.number = textField.text;
        
        self.textField          = textField;
        [textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    }

    return self;
}


// Only used when there's a clear button (which we don't have now; see Common).
- (BOOL)textFieldShouldClear:(UITextField*)textField
{
    self.phoneNumber.number = @"";

    return YES;
}


- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    [textField resignFirstResponder];

    return YES;
}


- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string
{
    self.phoneNumber.number = [textField.text stringByReplacingCharactersInRange:range withString:string];

    // This is needed because the AYT formatter, when backspacing, turns "+44" again into "+44 "
    // so you'd never to get rid of the country code anymore.
    if ([textField.text isEqualToString:self.phoneNumber.asYouTypeFormat])
    {
        textField.text          = @"";
        self.phoneNumber.number = @"";
    }

    return YES;
}


// Not a delegate method.
- (void)textFieldDidChange:(UITextField*)textField
{
    textField.text = self.phoneNumber.asYouTypeFormat;
}

@end
