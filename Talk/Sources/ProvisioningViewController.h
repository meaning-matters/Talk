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
@property (nonatomic, strong) IBOutlet UIView*                  busyView;
@property (nonatomic, strong) IBOutlet UIView*                  failView;
@property (nonatomic, strong) IBOutlet UIView*                  readyView;


// Intro View
@property (nonatomic, weak) IBOutlet UINavigationBar*           introNavigationBar;
@property (nonatomic, weak) IBOutlet UITextView*                introTextView;
@property (nonatomic, weak) IBOutlet UIButton*                  introRestoreButton;
@property (nonatomic, weak) IBOutlet UIButton*                  introBuyButton;

// Busy View
@property (nonatomic, weak) IBOutlet UINavigationBar*           busyNavigationBar;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView*   busyActivityIndicator;
@property (nonatomic, weak) IBOutlet UILabel*                   busyLabel;

// Fail View
@property (nonatomic, weak) IBOutlet UINavigationBar*           failNavigationBar;
@property (nonatomic, weak) IBOutlet UITextView*                failTextView;
@property (nonatomic, weak) IBOutlet UIButton*                  failCloseButton;

// Ready View
@property (nonatomic, weak) IBOutlet UINavigationBar*           readyNavigationBar;
@property (nonatomic, weak) IBOutlet UITextView*                readyTextView;
@property (nonatomic, weak) IBOutlet UIButton*                  readyCreditButton;
@property (nonatomic, weak) IBOutlet UIButton*                  readyNumberButton;


// Intro View
- (IBAction)introCancelAction:(id)sender;
- (IBAction)introRestoreAction:(id)sender;
- (IBAction)introBuyAction:(id)sender;

// Busy View
- (IBAction)busyCancelAction:(id)sender;

// Fail View
- (IBAction)failCancelAction:(id)sender;
- (IBAction)failCloseAction:(id)sender;

// Ready View
- (IBAction)readyCancelAction:(id)sender;
- (IBAction)readyCreditAction:(id)sender;
- (IBAction)readyNumberAction:(id)sender;

@end
