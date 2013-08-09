//
//  ProvisioningViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 10/02/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProvisioningViewController : UIViewController

// The views.
@property (nonatomic, strong) IBOutlet UIView*                  introView;
@property (nonatomic, strong) IBOutlet UIView*                  verifyView;
@property (nonatomic, strong) IBOutlet UIView*                  readyView;

// Intro View
@property (nonatomic, weak) IBOutlet UINavigationBar*           introNavigationBar;
@property (nonatomic, weak) IBOutlet UITextView*                introTextView;
@property (nonatomic, weak) IBOutlet UIButton*                  introRestoreButton;
@property (nonatomic, weak) IBOutlet UIButton*                  introBuyButton;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView*   introRestoreActivityIndicator;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView*   introBuyActivityIndicator;

// Verify View
@property (nonatomic, weak) IBOutlet UINavigationBar*           verifyNavigationBar;
@property (nonatomic, weak) IBOutlet UITextView*                verifyTextView;
@property (nonatomic, weak) IBOutlet UIView*                    verifyStep1View;
@property (nonatomic, weak) IBOutlet UIView*                    verifyStep2View;
@property (nonatomic, weak) IBOutlet UIView*                    verifyStep3View;
@property (nonatomic, weak) IBOutlet UILabel*                   verifyStep1Label;
@property (nonatomic, weak) IBOutlet UILabel*                   verifyStep2Label;
@property (nonatomic, weak) IBOutlet UILabel*                   verifyStep3Label;
@property (nonatomic, weak) IBOutlet UIButton*                  verifyNumberButton;
@property (nonatomic, weak) IBOutlet UIButton*                  verifyCallButton;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView*   verifyCallActivityIndicator;
@property (nonatomic, weak) IBOutlet UILabel*                   verifyCodeLabel;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView*   verifyCodeActivityIndicator;

// Ready View
@property (nonatomic, weak) IBOutlet UINavigationBar*           readyNavigationBar;
@property (nonatomic, weak) IBOutlet UITextView*                readyTextView;
@property (nonatomic, weak) IBOutlet UIButton*                  readyCreditButton;
@property (nonatomic, weak) IBOutlet UIButton*                  readyNumberButton;

// Intro View
- (IBAction)introCancelAction:(id)sender;
- (IBAction)introRestoreAction:(id)sender;
- (IBAction)introBuyAction:(id)sender;

// Verify View
- (IBAction)verifyCancelAction:(id)sender;
- (IBAction)verifyNumberAction:(id)sender;
- (IBAction)verifyCallAction:(id)sender;

// Ready View
- (IBAction)readyDoneAction:(id)sender;
- (IBAction)readyCreditAction:(id)sender;
- (IBAction)readyNumberAction:(id)sender;

@end
