//
//  BlockAlertView.m
//  Talk
//
//  Created by Cornelis van der Bent on 23/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "BlockAlertView.h"
#import "PhoneNumberTextFieldDelegate.h"
#import "Common.h"


@interface BlockAlertView ()

@property (nonatomic, copy) void (^completion)(BOOL cancelled, NSInteger buttonIndex);
@property (nonatomic, copy) void (^phoneNumberCompletion)(BOOL cancelled, NSInteger buttonIndex, PhoneNumber* phoneNumber);
@property (nonatomic, strong) PhoneNumberTextFieldDelegate* phoneNumberTextFieldDelegate;

@end


@implementation BlockAlertView

+ (BlockAlertView*)showAlertViewWithTitle:(NSString*)title
                                  message:(NSString*)message
                               completion:(void (^)(BOOL cancelled, NSInteger buttonIndex))completion
                        cancelButtonTitle:(NSString*)cancelButtonTitle
                        otherButtonTitles:(NSString*)otherButtonTitles, ...
{
    va_list arguments;
    va_start(arguments, otherButtonTitles);

    BlockAlertView* alert = [[BlockAlertView alloc] initWithTitle:title
                                                          message:message
                                                        completion:completion
                                                cancelButtonTitle:cancelButtonTitle
                                                otherButtonTitles:otherButtonTitles
                                                        arguments:arguments];
    [alert show];

    va_end(arguments);

    return alert;
}


+ (BlockAlertView*)showPhoneNumberAlertViewWithTitle:(NSString*)title
                                             message:(NSString*)message
                                          completion:(void (^)(BOOL         cancelled,
                                                               NSInteger    buttonIndex,
                                                               PhoneNumber* phoneNumber))completion
                                   cancelButtonTitle:(NSString*)cancelButtonTitle
                                   otherButtonTitles:(NSString*)otherButtonTitles, ...
{
    va_list arguments;
    va_start(arguments, otherButtonTitles);

    __block BlockAlertView* alert = [[BlockAlertView alloc] initWithTitle:title
                                                                  message:message
                                                               completion:^(BOOL cancelled, NSInteger buttonIndex)
    {
    }
                                                        cancelButtonTitle:cancelButtonTitle
                                                        otherButtonTitles:otherButtonTitles
                                                                arguments:arguments];

    alert.alertViewStyle    = UIAlertViewStylePlainTextInput;
    
    UITextField* textField  = [alert textFieldAtIndex:0];
    textField.textAlignment = NSTextAlignmentCenter;
    [textField setKeyboardType:UIKeyboardTypePhonePad];

    alert->_phoneNumberCompletion      = completion;
    alert.phoneNumberTextFieldDelegate = [[PhoneNumberTextFieldDelegate alloc] initWithTextField:textField];
    textField.delegate                 = alert.phoneNumberTextFieldDelegate;
                          
    [alert show];

    va_end(arguments);
    
    return alert;
}


- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (self.phoneNumberTextFieldDelegate != nil && buttonIndex == 1)
    {
        if ([Common checkCountryOfPhoneNumber:self.phoneNumberTextFieldDelegate.phoneNumber
                                   completion:^(PhoneNumber* phoneNumber)
        {
            if ([phoneNumber isValid] == YES)
            {
                self.phoneNumberCompletion(NO, 1, phoneNumber);
            }
            else
            {
                self.phoneNumberCompletion(YES, 0, phoneNumber);
            }
        }] == YES)
        {
            self.phoneNumberCompletion(YES, 1, self.phoneNumberTextFieldDelegate.phoneNumber);
        }
    }
    
    [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
}


- (BlockAlertView*)initWithTitle:(NSString*)title
                         message:(NSString*)message
                      completion:(void (^)(BOOL cancelled, NSInteger buttonIndex))completion
               cancelButtonTitle:(NSString*)cancelButtonTitle
               otherButtonTitles:(NSString*)otherButtonTitles
                       arguments:(va_list)arguments
{
    self = [super initWithTitle:title
                        message:message
                       delegate:self
              cancelButtonTitle:cancelButtonTitle
              otherButtonTitles:nil];

    if (self)
    {
        _completion = completion;

        for (NSString* title = otherButtonTitles; title != nil; title = (__bridge NSString*)va_arg(arguments, void*))
        {
            [self addButtonWithTitle:title];
        }
    }

    return self;
}


- (void)alertView:(UIAlertView*)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (self.completion != nil)
    {
        self.completion(buttonIndex == self.cancelButtonIndex, buttonIndex);
    }
}

@end
