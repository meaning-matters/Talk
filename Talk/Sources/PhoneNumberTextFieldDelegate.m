//
//  PhoneNumberTextFieldDelegate.m
//  Talk
//
//  Created by Cornelis van der Bent on 03/08/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
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
        self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        [self.textField setKeyboardType:UIKeyboardTypePhonePad];

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
    if ([textField.text isEqualToString:self.phoneNumber.asYouTypeFormat] && (string.length == 0) &&
        (range.location == (textField.text.length - 1)) && (range.location > 0) && (range.length == 1))
    {
        range = NSMakeRange((range.location - 1), 2);
        self.phoneNumber.number = [textField.text stringByReplacingCharactersInRange:range withString:string];
    }

    return YES;
}


- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    return YES;
}


// Not a delegate method.
- (void)textFieldDidChange:(UITextField*)textField
{
    textField.text = self.phoneNumber.asYouTypeFormat;
}


- (void)update
{
    [self textFieldDidChange:self.textField];
}

@end
