//
//  AppDelegate.h
//  Talk
//
//  Created by Cornelis van der Bent on 28/09/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AboutViewController.h"
#import "CreditViewController.h"
#import "DialerViewController.h"
#import "ForwardingsViewController.h"
#import "GroupsViewController.h"
#import "HelpViewController.h"
#import "NumbersViewController.h"
#import "RecentsViewController.h"
#import "ShareViewController.h"
#import "SettingsViewController.h"
#import "SipInterface.h"


@interface AppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate>

@property (nonatomic, strong) UIWindow*                     window;
@property (nonatomic, strong) UITabBarController*           tabBarController;

@property (nonatomic, strong) AboutViewController*          aboutViewController;
@property (nonatomic, strong) CreditViewController*         creditViewController;
@property (nonatomic, strong) DialerViewController*         dialerViewController;
@property (nonatomic, strong) ForwardingsViewController*    forwardingsViewController;
@property (nonatomic, strong) GroupsViewController*         groupsViewController;
@property (nonatomic, strong) HelpViewController*           helpViewController;
@property (nonatomic, strong) NumbersViewController*        numbersViewController;
@property (nonatomic, strong) RecentsViewController*        recentsViewController;
@property (nonatomic, strong) ShareViewController*          shareViewController;
@property (nonatomic, strong) SettingsViewController*       settingsViewController;

@property (nonatomic, strong) SipInterface*                 sipInterface;

@end
