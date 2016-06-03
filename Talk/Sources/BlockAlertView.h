//
//  BlockAlertView.h
//  Talk
//
//  Created by Cornelis van der Bent on 23/11/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PhoneNumber.h"


@interface BlockAlertView : UIAlertView <UIAlertViewDelegate>

+ (BlockAlertView*)showAlertViewWithTitle:(NSString*)title
                                  message:(NSString*)message
                               completion:(void (^)(BOOL cancelled, NSInteger buttonIndex))completion
                        cancelButtonTitle:(NSString*)cancelButtonTitle
                        otherButtonTitles:(NSString*)otherButtonTitles, ...;

+ (BlockAlertView*)showPhoneNumberAlertViewWithTitle:(NSString*)title
                                             message:(NSString*)message
                                         phoneNumber:(PhoneNumber*)phoneNumber
                                          completion:(void (^)(BOOL         cancelled,
                                                               PhoneNumber* phoneNumber))completion
                                   cancelButtonTitle:(NSString*)cancelButtonTitle
                                   otherButtonTitles:(NSString*)otherButtonTitles, ...;

+ (BlockAlertView*)showTextAlertViewWithTitle:(NSString*)title
                                      message:(NSString*)message
                                         text:(NSString*)text
                                   completion:(void (^)(BOOL      cancelled,
                                                        NSInteger buttonIndex,
                                                        NSString* text))completion
                            cancelButtonTitle:(NSString*)cancelButtonTitle
                            otherButtonTitles:(NSString*)otherButtonTitles, ...;

@end
