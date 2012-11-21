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


@interface DialerViewController ()
{
    PhoneNumber*    phoneNumber;    // Holds the current number on screen.
}

@end


@implementation DialerViewController

@synthesize delegate    = _delegate;
@synthesize keypadView  = _keypadView;
@synthesize infoLabel   = _infoLabel;
@synthesize numberField = _numberField;
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
                 phoneNumber = [[PhoneNumber alloc] initWithNumber:phoneNumber.number];
                 self.numberField.text = phoneNumber.asYouTypeFormat;
             }
         }];
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.numberField setFont:[Common phoneFontOfSize:38]];

    self.keypadView.delegate = self;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // This will clear the field when coming back from call.
    self.numberField.text = phoneNumber.asYouTypeFormat;
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
            [Common setY:24       ofView:self.numberField];
            [Common setY:64       ofView:self.nameLabel];
            [Common setY:91       ofView:self.keypadView];
            [Common setHeight:275 ofView:self.keypadView];
            break;

        case 411:   // 320x480 screen, regular tab.
            [Common setY:2        ofView:self.infoLabel];
            [Common setY:24       ofView:self.numberField];
            [Common setY:64       ofView:self.nameLabel];
            [Common setY:91       ofView:self.keypadView];
            [Common setHeight:320 ofView:self.keypadView];
            break;

        case 455:   // 320x568 screen, regular tab.
            [Common setY:7        ofView:self.infoLabel];
            [Common setY:33       ofView:self.numberField];
            [Common setY:77       ofView:self.nameLabel];
            [Common setY:110      ofView:self.keypadView];
            [Common setHeight:345 ofView:self.keypadView];
            break;

        case 499:   // 320x568 screen, regular tab.
            [Common setY:6        ofView:self.infoLabel];
            [Common setY:32       ofView:self.numberField];
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


#pragma mark - KeypadView Delegate

- (void)keypadView:(KeypadView*)keypadView pressedDigitKey:(KeypadKey)key
{
    phoneNumber.number = [NSString stringWithFormat:@"%@%c", phoneNumber.number, key];
    self.numberField.text = phoneNumber.asYouTypeFormat;
}


- (void)keypadViewPressedOptionKey:(KeypadView*)keypadView
{
    NSLog(@"OPTION");
}


- (void)keypadViewPressedCallKey:(KeypadView*)keypadView
{
    if ([self.numberField.text length] == 0)
    {
        phoneNumber.number = [Settings sharedSettings].lastDialedNumber;
        self.numberField.text = phoneNumber.asYouTypeFormat;
    }
    else
    {
        [Settings sharedSettings].lastDialedNumber = phoneNumber.number;
        [self.delegate dialerViewController:self callPhoneNumber:phoneNumber];
        phoneNumber = [[PhoneNumber alloc] init];
    }
}


- (void)keypadViewPressedEraseKey:(KeypadView*)keypadView
{
    if ([phoneNumber.number length] > 0)
    {
        phoneNumber.number = [phoneNumber.number substringToIndex:[phoneNumber.number length] - 1];
        self.numberField.text = phoneNumber.asYouTypeFormat;
    }
}

@end
