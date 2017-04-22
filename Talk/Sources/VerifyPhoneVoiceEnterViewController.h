//
//  VerifyPhoneVoiceEnterViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 28/03/17.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PhoneNumber;


@interface VerifyPhoneVoiceEnterViewController : UITableViewController

- (instancetype)initWithCompletion:(void (^)(PhoneNumber* verifiedPhoneNumber, NSString* uuid))completion;

@end
