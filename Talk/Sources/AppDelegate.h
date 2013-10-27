//
//  AppDelegate.h
//  Talk
//
//  Created by Cornelis van der Bent on 28/09/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "HockeySDK.h"
#import "AboutViewController.h"
#import "CreditViewController.h"
#import "DialerViewController.h"
#import "ForwardingsViewController.h"
#import "GroupsViewController.h"
#import "HelpsViewController.h"
#import "NumbersViewController.h"
#import "ShareViewController.h"
#import "SettingsViewController.h"
#import "NBPeoplePickerNavigationController.h"
#import "NBRecentsNavigationController.h"


@interface AppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate, AVAudioPlayerDelegate,
                                      BITHockeyManagerDelegate, BITCrashManagerDelegate>

@property (nonatomic, strong) UIWindow*                                 window;
@property (nonatomic, strong) UITabBarController*                       tabBarController;

@property (nonatomic, strong) NSString*                                 deviceToken;

@property (nonatomic, strong) AboutViewController*                      aboutViewController;
@property (nonatomic, strong) CreditViewController*                     creditViewController;
@property (nonatomic, strong) DialerViewController*                     dialerViewController;
@property (nonatomic, strong) ForwardingsViewController*                forwardingsViewController;
@property (nonatomic, strong) GroupsViewController*                     groupsViewController;
@property (nonatomic, strong) HelpsViewController*                      helpsViewController;
@property (nonatomic, strong) NumbersViewController*                    numbersViewController;
@property (nonatomic, strong) ShareViewController*                      shareViewController;
@property (nonatomic, strong) SettingsViewController*                   settingsViewController;
@property (nonatomic, strong) NBPeoplePickerNavigationController*       peoplePickerViewController;
@property (nonatomic, strong) NBRecentsNavigationController*            recentsViewController;

+ (AppDelegate*)appDelegate;

- (void)resetAll;

- (void)restore;

@end
