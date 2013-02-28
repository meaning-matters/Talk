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
@property (nonatomic, strong) IBOutlet UIView*          introView;

// Intro View
@property (nonatomic, weak) IBOutlet UINavigationBar*   introNavigationBar;
@property (nonatomic, weak) IBOutlet UIButton*          introRestoreButton;
@property (nonatomic, weak) IBOutlet UIButton*          introBuyButton;

// Intro View
- (IBAction)introCancelAction:(id)sender;
- (IBAction)introRestoreAction:(id)sender;
- (IBAction)introBuyAction:(id)sender;


@end
