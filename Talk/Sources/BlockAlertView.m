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
@property (nonatomic, copy) void (^phoneNumberCompletion)(BOOL cancelled, PhoneNumber* phoneNumber);
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


+ (NSInteger)showBlockingAlertViewWithTitle:(NSString*)title
                                    message:(NSString*)message
                          cancelButtonTitle:(NSString*)cancelButtonTitle
                          otherButtonTitles:(NSString*)otherButtonTitles, ...
{
    __block BOOL        dismissed   = NO;
    __block NSInteger   index = 0;

    va_list arguments;
    va_start(arguments, otherButtonTitles);

    BlockAlertView* alert = [[BlockAlertView alloc] initWithTitle:title
                                                          message:message
                                                       completion:^(BOOL cancelled, NSInteger buttonIndex)
    {
        index     = buttonIndex;
        dismissed = YES;
    }
                                                cancelButtonTitle:cancelButtonTitle
                                                otherButtonTitles:otherButtonTitles
                                                        arguments:arguments];
    [alert show];

    va_end(arguments);

    // 'Busy loop', waiting for user to dismiss alert.
    while (dismissed == NO)
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }

    return index;
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

    __block BlockAlertView* alert = [[BlockAlertView alloc] initWithTitle:title
                                                                  message:message
                                                               completion:^(BOOL cancelled, NSInteger buttonIndex)
    {
        // Only the cancel must be handled here.
        if (cancelled == YES)
        {
            alert->_phoneNumberCompletion(cancelled, phoneNumber);
        }
    }
                                                        cancelButtonTitle:cancelButtonTitle
                                                        otherButtonTitles:otherButtonTitles
                                                                arguments:arguments];

    alert.alertViewStyle               = UIAlertViewStylePlainTextInput;
    
    UITextField* textField             = [alert textFieldAtIndex:0];
    textField.textAlignment            = NSTextAlignmentCenter;
    textField.autocorrectionType       = UITextAutocorrectionTypeNo;
    textField.text                     = [phoneNumber asYouTypeFormat];
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
                                   completion:^(BOOL cancelled, PhoneNumber* phoneNumber)
        {
            self.phoneNumberCompletion(cancelled, phoneNumber);
        }] == YES)
        {
            // Number already has ISO country code; call completion now.
            self.phoneNumberCompletion(NO, self.phoneNumberTextFieldDelegate.phoneNumber);
        }
        else
        {
            // No ISO country code yet; wait for checkCountryOfPhoneNumber to complete.
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
