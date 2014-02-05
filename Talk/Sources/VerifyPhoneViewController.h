//
//  VerifyPhoneViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 02/02/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PhoneNumber;


@interface VerifyPhoneViewController : UIViewController

- (instancetype)initWithCompletion:(void (^)(PhoneNumber* verifiedPhoneNumber))completion;

@property (nonatomic, weak) IBOutlet UITextView*              textView;
@property (nonatomic, weak) IBOutlet UIView*                  step1View;
@property (nonatomic, weak) IBOutlet UIView*                  step2View;
@property (nonatomic, weak) IBOutlet UIView*                  step3View;
@property (nonatomic, weak) IBOutlet UILabel*                 step1Label;
@property (nonatomic, weak) IBOutlet UILabel*                 step2Label;
@property (nonatomic, weak) IBOutlet UILabel*                 step3Label;
@property (nonatomic, weak) IBOutlet UIButton*                numberButton;
@property (nonatomic, weak) IBOutlet UIButton*                callButton;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* callActivityIndicator;
@property (nonatomic, weak) IBOutlet UILabel*                 codeLabel;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* codeActivityIndicator;

@end
