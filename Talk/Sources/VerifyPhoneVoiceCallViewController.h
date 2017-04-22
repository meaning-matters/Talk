//
//  VerifyPhoneVoiceCallViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 08/04/17.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PhoneNumber;


@interface VerifyPhoneVoiceCallViewController : UITableViewController

- (instancetype)initWithPhoneNumber:(PhoneNumber*)phoneNumber
                         completion:(void (^)(PhoneNumber* verifiedPhoneNumber, NSString* uuid))completion;

@end
