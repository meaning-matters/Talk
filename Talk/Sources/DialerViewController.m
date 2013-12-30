//
//  DialerViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "DialerViewController.h"
#import "Common.h"
#import "PhoneNumber.h"
#import "Settings.h"
#import "NetworkStatus.h"
#import "CountryNames.h"
#import "DtmfPlayer.h"
#import "CallManager.h"


@interface DialerViewController ()
{
    PhoneNumber*    phoneNumber;    // Holds the current number on screen.
}

@end


@implementation DialerViewController 

@synthesize keypadView  = _keypadView;

- (instancetype)init
{
    if (self = [super initWithNibName:@"DialerView" bundle:nil])
    {
        self.title = NSLocalizedString(@"Dialer", @"Dialer tab title");
        self.tabBarItem.image = [UIImage imageNamed:@"DialerTab.png"];

        // We don't want navigation bar when dialer is on main tabs.  (It will
        // always get a navigation bar, when moved to more tab.)
        navigationController.navigationBar.hidden = YES;

        phoneNumber = [[PhoneNumber alloc] init];
        [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification* note)
        {
            if ([phoneNumber.isoCountryCode isEqualToString:[Settings sharedSettings].homeCountry] == NO)
            {
                [PhoneNumber setDefaultIsoCountryCode:[Settings sharedSettings].homeCountry];
                phoneNumber = [[PhoneNumber alloc] initWithNumber:phoneNumber.number];
                [self update];
            }

            if ([Settings sharedSettings].allowCellularDataCalls == YES)
            {
                [self updateReachable];
            }
        }];

        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification* note)
        {
            // This will clear the field when coming back from mobile call.
            [self update];
        }];

        [[NSNotificationCenter defaultCenter] addObserverForName:NetworkStatusReachableNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification* note)
         {
             [self updateReachable];
         }];

        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification* note)
        {
            if (self.isViewLoaded && self.view.window)
            {
                [[DtmfPlayer sharedPlayer] startKeepAlive];  // See DtmfPlayer.m why this is needed.
            }
        }];

        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification* note)
        {
            if (self.isViewLoaded && self.view.window)
            {
                [[DtmfPlayer sharedPlayer] stopKeepAlive]; // See DtmfPlayer.m why this is needed.
            }
        }];
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.numberLabel setFont:[Common phoneFontOfSize:38]];
    self.numberLabel.hasPaste = YES;
    self.numberLabel.delegate = self;

    self.keypadView.delegate = self;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // This will clear the field when coming back from call.
    [self update];

    [[DtmfPlayer sharedPlayer] startKeepAlive]; // See DtmfPlayer.m why this is needed.
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [[DtmfPlayer sharedPlayer] stopKeepAlive];  // See DtmfPlayer.m why this is needed.
}


- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    // We deliberately set the KeypadView height to a fivefold, so that all keys
    // can be equally high.  This is assumed in the layout code of KeypadView!
    switch ((int)self.view.frame.size.height)
    {
        case 367:   // 320x480 screen, More tab.
            [Common setY:10       ofView:self.brandingImageView];
            [Common setY:2        ofView:self.infoLabel];
            [Common setY:24       ofView:self.numberLabel];
            [Common setY:64       ofView:self.nameLabel];
            [Common setY:91       ofView:self.keypadView];
            [Common setHeight:275 ofView:self.keypadView];
            break;

        case 347:   // 320x480 screen, More tab, with in-call iOS flasher at top.
            [Common setY:10       ofView:self.brandingImageView];
            [Common setY:2        ofView:self.infoLabel];
            [Common setY:24       ofView:self.numberLabel];
            [Common setY:64       ofView:self.nameLabel];
            [Common setY:91       ofView:self.keypadView];
            [Common setHeight:255 ofView:self.keypadView];
            break;

        case 411:   // 320x480 screen, regular tab.
            [Common setY:10       ofView:self.brandingImageView];
            [Common setY:2        ofView:self.infoLabel];
            [Common setY:24       ofView:self.numberLabel];
            [Common setY:64       ofView:self.nameLabel];
            [Common setY:91       ofView:self.keypadView];
            [Common setHeight:320 ofView:self.keypadView];
            break;

        case 291:   // 320x480 screen, regular tab, with in-call iOS flasher at top.
            [Common setY:10       ofView:self.brandingImageView];
            [Common setY:2        ofView:self.infoLabel];
            [Common setY:24       ofView:self.numberLabel];
            [Common setY:64       ofView:self.nameLabel];
            [Common setY:91       ofView:self.keypadView];
            [Common setHeight:300 ofView:self.keypadView];
            break;

        case 455:   // 320x568 screen, More tab.
            [Common setY:15       ofView:self.brandingImageView];
            [Common setY:7        ofView:self.infoLabel];
            [Common setY:33       ofView:self.numberLabel];
            [Common setY:77       ofView:self.nameLabel];
            [Common setY:110      ofView:self.keypadView];
            [Common setHeight:345 ofView:self.keypadView];
            break;

        case 435:   // 320x568 screen, More tab, with in-call iOS flasher at top.
            [Common setY:15       ofView:self.brandingImageView];
            [Common setY:7        ofView:self.infoLabel];
            [Common setY:33       ofView:self.numberLabel];
            [Common setY:77       ofView:self.nameLabel];
            [Common setY:110      ofView:self.keypadView];
            [Common setHeight:325 ofView:self.keypadView];
            break;

        case 499:   // 320x568 screen, regular tab.
            [Common setY:14       ofView:self.brandingImageView];
            [Common setY:6        ofView:self.infoLabel];
            [Common setY:32       ofView:self.numberLabel];
            [Common setY:76       ofView:self.nameLabel];
            [Common setY:108      ofView:self.keypadView];
            [Common setHeight:390 ofView:self.keypadView];
            break;

        case 479:   // 320x568 screen, regular tab, with in-call iOS flasher at top.
            [Common setY:14       ofView:self.brandingImageView];
            [Common setY:6        ofView:self.infoLabel];
            [Common setY:32       ofView:self.numberLabel];
            [Common setY:76       ofView:self.nameLabel];
            [Common setY:108      ofView:self.keypadView];
            [Common setHeight:370 ofView:self.keypadView];
            break;
    }
}


#pragma mark - Utility Methods

- (void)updateReachable
{
    BOOL haveAccount   = [Settings sharedSettings].haveVerifiedAccount;
    BOOL allowCellular = [Settings sharedSettings].allowCellularDataCalls || [Settings sharedSettings].callbackMode;

    switch ([NetworkStatus sharedStatus].reachableStatus)
    {
        case NetworkStatusReachableDisconnected:
            self.keypadView.keyCallButton.selected = NO;
            break;

        case NetworkStatusReachableCellular:
            self.keypadView.keyCallButton.selected = haveAccount && (allowCellular || HAS_VOIP == NO);
            break;

        case NetworkStatusReachableWifi:
            self.keypadView.keyCallButton.selected = haveAccount;
            break;

        case NetworkStatusReachableCaptivePortal:
            self.keypadView.keyCallButton.selected = NO;
            break;
    }
}


- (void)update
{
    [self updateReachable];

    self.infoLabel.text   = [phoneNumber infoString];
    self.numberLabel.text = [phoneNumber asYouTypeFormat];

    if (phoneNumber.isEmergency)
    {
        self.keypadView.keyCallButton.selected = [NetworkStatus sharedStatus].allowsMobileCalls;
    }

    self.brandingImageView.hidden = self.numberLabel.text.length > 0;

    //### lookup number in Contacts...
    //### when found show name, else:
    self.nameLabel.text = @"";
}


#pragma mark - KeypadView Delegate

- (void)keypadView:(KeypadView*)keypadView pressedDigitKey:(KeypadKey)key
{
    phoneNumber.number = [NSString stringWithFormat:@"%@%c", phoneNumber.number, key];
    [self update];

    [[DtmfPlayer sharedPlayer] playCharacter:key atVolume:0.02f];
}


- (void)keypadViewPressedOptionKey:(KeypadView*)keypadView
{
    NSLog(@"OPTION");
}


- (void)keypadViewPressedCallKey:(KeypadView*)keypadView
{
    if ([self.numberLabel.text length] == 0)
    {
        phoneNumber.number = [Settings sharedSettings].lastDialedNumber;
        [self update];
    }
    else
    {
        NSString* identity = [Settings sharedSettings].callerIdE164; //### Select identity.
        Call*     call     = [[CallManager sharedManager] callPhoneNumber:phoneNumber fromIdentity:identity];

        if (call != nil)
        {
            // CallView will be shown, or mobile call is made.
            [Settings sharedSettings].lastDialedNumber = phoneNumber.number;
            phoneNumber = [[PhoneNumber alloc] init];

            [Common dispatchAfterInterval:0.5 onMain:^
            {
                // Clears UI fields.  This is done after a delay to make sure that
                // a call related view is on screen; keeping it out of sight.
                [self update];
            }];
        }
    }
}


- (void)keypadViewPressedEraseKey:(KeypadView*)keypadView
{
    if ([phoneNumber.number length] > 0)
    {
        phoneNumber.number = [phoneNumber.number substringToIndex:[phoneNumber.number length] - 1];
        [self update];
    }
}


#pragma mark - NumberLabel Delegate

- (void)numberLabelChanged:(NumberLabel*)numberLabel
{
    phoneNumber.number = numberLabel.text;
    [self update];
}

@end
