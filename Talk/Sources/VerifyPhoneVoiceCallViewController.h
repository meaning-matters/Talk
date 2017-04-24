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
                               uuid:(NSString*)uuid
                      languageCodes:(NSArray*)languageCodes
                         codeLength:(NSUInteger)codeLength
                         completion:(void (^)(BOOL isVerified))completion;

@end
