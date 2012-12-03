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
#import "CountryNames.h"
#import "DtmfPlayer.h"


@interface DialerViewController ()
{
    PhoneNumber*    phoneNumber;    // Holds the current number on screen.
}

@end


@implementation DialerViewController

@synthesize delegate    = _delegate;
@synthesize keypadView  = _keypadView;
@synthesize infoLabel   = _infoLabel;
@synthesize numberLabel = _numberLabel;
@synthesize nameLabel   = _nameLabel;


- (id)init
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
             if ([phoneNumber.baseIsoCountryCode isEqualToString:[Settings sharedSettings].homeCountry] == NO)
             {
                 [PhoneNumber setDefaultBaseIsoCountryCode:[Settings sharedSettings].homeCountry];
                 phoneNumber = [[PhoneNumber alloc] initWithNumber:phoneNumber.number]; //### Can this give memory problems???
                 [self update];
             }
         }];
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.numberLabel setFont:[Common phoneFontOfSize:38]];
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
            [Common setY:2        ofView:self.infoLabel];
            [Common setY:24       ofView:self.numberLabel];
            [Common setY:64       ofView:self.nameLabel];
            [Common setY:91       ofView:self.keypadView];
            [Common setHeight:275 ofView:self.keypadView];
            break;

        case 411:   // 320x480 screen, regular tab.
            [Common setY:2        ofView:self.infoLabel];
            [Common setY:24       ofView:self.numberLabel];
            [Common setY:64       ofView:self.nameLabel];
            [Common setY:91       ofView:self.keypadView];
            [Common setHeight:320 ofView:self.keypadView];
            break;

        case 455:   // 320x568 screen, regular tab.
            [Common setY:7        ofView:self.infoLabel];
            [Common setY:33       ofView:self.numberLabel];
            [Common setY:77       ofView:self.nameLabel];
            [Common setY:110      ofView:self.keypadView];
            [Common setHeight:345 ofView:self.keypadView];
            break;

        case 499:   // 320x568 screen, regular tab.
            [Common setY:6        ofView:self.infoLabel];
            [Common setY:32       ofView:self.numberLabel];
            [Common setY:76       ofView:self.nameLabel];
            [Common setY:108      ofView:self.keypadView];
            [Common setHeight:390 ofView:self.keypadView];
            break;
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - Utility Methods

- (void)update
{
    self.numberLabel.text = phoneNumber.asYouTypeFormat;
    if (phoneNumber.isValid)
    {
        NSString*   impossible;

        if (phoneNumber.isPossible == NO)
        {
            impossible = NSLocalizedStringWithDefaultValue(@"General:Number Impossible", nil,
                                                           [NSBundle mainBundle], @"impossible",
                                                           @"Indicates that the phone number is impossible (i.e. can't exist)\n"
                                                           @"[0.5 line small font].");
            
            self.infoLabel.text = [NSString stringWithFormat:@"%@ (%@)", [phoneNumber typeString], impossible];
        }
        else
        {
            self.infoLabel.text = [NSString stringWithFormat:@"%@", [phoneNumber typeString]];
        }
    }
    else
    {
        self.infoLabel.text = @"";
    }

    //### lookup number in Contacts...
    //### when found show name, else:
    self.nameLabel.text = [[CountryNames sharedNames] nameForIsoCountryCode:[phoneNumber isoCountryCode]];
}


#pragma mark - KeypadView Delegate

- (void)keypadView:(KeypadView*)keypadView pressedDigitKey:(KeypadKey)key
{
    phoneNumber.number = [NSString stringWithFormat:@"%@%c", phoneNumber.number, key];
    [self update];

    [[DtmfPlayer sharedPlayer] playForCharacter:key];
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
        if ([self.delegate dialerViewController:self callPhoneNumber:phoneNumber] == YES)
        {
            // Delegate will show call screen.
            [Settings sharedSettings].lastDialedNumber = phoneNumber.number;
            phoneNumber = [[PhoneNumber alloc] init];

            // We don't clear numberLabel.text as this would be disruptive
            // during the animation to call screen.  Cleared in viewDidAppear.
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
