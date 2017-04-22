//
//  BlockAlertView.m
//  Talk
//
//  Created by Cornelis van der Bent on 23/11/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import "BlockAlertView.h"
#import "PhoneNumberTextFieldDelegate.h"
#import "Common.h"


@interface BlockAlertView ()

@property (nonatomic, copy) void (^completion)(BOOL cancelled, NSInteger buttonIndex);
@property (nonatomic, copy) void (^phoneNumberCompletion)(BOOL cancelled, PhoneNumber* phoneNumber);
@property (nonatomic, copy) void (^textCompletion)(BOOL cancelled, NSInteger buttonIndex, NSString* text);
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

    BlockAlertView* alertView = [[BlockAlertView alloc] initWithTitle:title
                                                              message:message
                                                           completion:completion
                                                    cancelButtonTitle:cancelButtonTitle
                                                    otherButtonTitles:otherButtonTitles
                                                            arguments:arguments];
    [alertView show];

    va_end(arguments);

    return alertView;
}


+ (BlockAlertView*)showPhoneNumberAlertViewWithTitle:(NSString*)title
                                             message:(NSString*)message
                                         phoneNumber:(PhoneNumber*)phoneNumber
                                          completion:(void (^)(BOOL         cancelled,
                                                               PhoneNumber* phoneNumber))completion
                                   cancelButtonTitle:(NSString*)cancelButtonTitle
                                   otherButtonTitles:(NSString*)otherButtonTitles, ...
{
    va_list arguments;
    va_start(arguments, otherButtonTitles);

    __block BlockAlertView* alertView = [[BlockAlertView alloc] initWithTitle:title
                                                                      message:message
                                                                   completion:^(BOOL cancelled, NSInteger buttonIndex)
    {
        UITextField* textField = [alertView textFieldAtIndex:0];
        [textField resignFirstResponder];
        
        // Only the cancel must be handled here.
        if (cancelled == YES)
        {
            alertView->_phoneNumberCompletion ? alertView->_phoneNumberCompletion(cancelled, phoneNumber) : 0;
        }
    }
                                                        cancelButtonTitle:cancelButtonTitle
                                                        otherButtonTitles:otherButtonTitles
                                                                arguments:arguments];

    alertView.alertViewStyle               = UIAlertViewStylePlainTextInput;
    
    UITextField* textField                 = [alertView textFieldAtIndex:0];
    textField.textAlignment                = NSTextAlignmentCenter;
    textField.text                         = [phoneNumber asYouTypeFormat]; // Note, can't use this to init a string; can be nil.

    alertView->_phoneNumberCompletion      = [completion copy];
    alertView.phoneNumberTextFieldDelegate = [[PhoneNumberTextFieldDelegate alloc] initWithTextField:textField];
    textField.delegate                     = alertView.phoneNumberTextFieldDelegate;
                          
    [alertView show];
    textField.font                         = [UIFont boldSystemFontOfSize:18.0f]; // Needs to be placed after `show` to work.

    va_end(arguments);
    
    return alertView;
}


+ (BlockAlertView*)showTextAlertViewWithTitle:(NSString*)title
                                      message:(NSString*)message
                                         text:(NSString*)text
                                   completion:(void (^)(BOOL      cancelled,
                                                        NSInteger buttonIndex,
                                                        NSString* text))completion
                            cancelButtonTitle:(NSString*)cancelButtonTitle
                            otherButtonTitles:(NSString*)otherButtonTitles, ...
{
    va_list arguments;
    va_start(arguments, otherButtonTitles);
    
    __block BlockAlertView* alertView = [[BlockAlertView alloc] initWithTitle:title
                                                                      message:message
                                                                   completion:^(BOOL cancelled, NSInteger buttonIndex)
    {
        UITextField* textField = [alertView textFieldAtIndex:0];
        [textField resignFirstResponder];
        
        alertView->_textCompletion ? alertView->_textCompletion(cancelled, buttonIndex, textField.text) : 0;
    }
                                                        cancelButtonTitle:cancelButtonTitle
                                                        otherButtonTitles:otherButtonTitles
                                                                arguments:arguments];
    
    alertView.alertViewStyle     = UIAlertViewStylePlainTextInput;
    
    UITextField* textField       = [alertView textFieldAtIndex:0];
    textField.textAlignment      = NSTextAlignmentCenter;
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.text               = text;
    
    alertView->_textCompletion   = [completion copy];
    
    [alertView show];
    textField.font               = [UIFont systemFontOfSize:18.0f];   // Needs to be placed after `show` to work.
    
    va_end(arguments);
    
    return alertView;
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
        _completion = [completion copy];

        for (NSString* title = otherButtonTitles; title != nil; title = (__bridge NSString*)va_arg(arguments, void*))
        {
            [self addButtonWithTitle:title];
        }
    }

    return self;
}


#pragma mark - Alert View Delegate

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (self.phoneNumberTextFieldDelegate != nil && buttonIndex == 1)
    {
        if ([Common checkCountryOfPhoneNumber:self.phoneNumberTextFieldDelegate.phoneNumber
                                   completion:^(BOOL cancelled, PhoneNumber* phoneNumber)
            {
                self.phoneNumberCompletion ? self.phoneNumberCompletion(cancelled, phoneNumber) : 0;
            }] == YES)
        {
            // We delay to allow the keyboard to disappear, avoiding ghost keyboards to appear briefly after closing
            // an alert created from the completion (http://stackoverflow.com/q/32095734/1971013)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.333 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
            {
                // Number already has ISO country code; call completion now.
                self.phoneNumberCompletion ? self.phoneNumberCompletion(NO, self.phoneNumberTextFieldDelegate.phoneNumber) : 0;
            });
        }
        else
        {
            // No ISO country code yet; wait for checkCountryOfPhoneNumber to complete.
        }
    }

    [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
}


- (void)alertView:(UIAlertView*)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    self.completion ? self.completion(buttonIndex == alertView.cancelButtonIndex, buttonIndex) : 0;
}

@end
