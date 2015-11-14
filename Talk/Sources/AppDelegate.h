//
//  AppDelegate.h
//  Talk
//
//  Created by Cornelis van der Bent on 28/09/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "HockeySDK.h"
#import "AboutViewController.h"
#import "CreditViewController.h"
#import "KeypadViewController.h"
#import "DestinationsViewController.h"
#import "GroupsViewController.h"
#import "HelpsViewController.h"
#import "NumbersViewController.h"
#import "ShareViewController.h"
#import "SettingsViewController.h"
#import "PhonesViewController.h"
#import "RatesViewController.h"
#import "NBPeoplePickerNavigationController.h"
#import "NBRecentsNavigationController.h"
#import "NBAddressBookManager.h"


@interface AppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate, AVAudioPlayerDelegate,
                                      UINavigationControllerDelegate,
                                      BITHockeyManagerDelegate, BITCrashManagerDelegate, AddressBookDelegate>

@property (nonatomic, strong) UIWindow*                           window;
@property (nonatomic, strong) UITabBarController*                 tabBarController;

@property (nonatomic, strong) NSString*                           deviceToken;

@property (nonatomic, strong) CreditViewController*               creditViewController;
@property (nonatomic, strong) NBRecentsNavigationController*      recentsViewController;
@property (nonatomic, strong) NBPeoplePickerNavigationController* peoplePickerViewController;
@property (nonatomic, strong) KeypadViewController*               keypadViewController;
@property (nonatomic, strong) PhonesViewController*               phonesViewController;
@property (nonatomic, strong) NumbersViewController*              numbersViewController;
@property (nonatomic, strong) DestinationsViewController*         destinationsViewController;
@property (nonatomic, strong) RatesViewController*                ratesViewController;
@property (nonatomic, strong) SettingsViewController*             settingsViewController;
@property (nonatomic, strong) HelpsViewController*                helpsViewController;
@property (nonatomic, strong) AboutViewController*                aboutViewController;
@property (nonatomic, strong) GroupsViewController*               groupsViewController;
@property (nonatomic, strong) ShareViewController*                shareViewController;

+ (AppDelegate*)appDelegate;

- (void)resetAll;

- (void)restore;

- (void)playWelcome;

- (void)findContactsHavingNumber:(NSString*)number completion:(void(^)(NSArray* contactIds))completion;

- (NSString*)contactNameForId:(NSString*)contactId;

@end
