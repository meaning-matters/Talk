//
//  DialerViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "DialerViewController.h"
#import "Common.h"

@interface DialerViewController ()

@end


@implementation DialerViewController

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
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.numberField setFont:[Common phoneFontOfSize:38]];

    self.keypadView.delegate = self;
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
    NSLog(@"DIGIT: %c", key);
}


- (void)keypadViewPressedOptionKey:(KeypadView*)keypadView
{
    NSLog(@"OPTION");
}


- (void)keypadViewPressedCallKey:(KeypadView*)keypadView
{
    NSLog(@"CALL");

}


- (void)keypadViewPressedEraseKey:(KeypadView*)keypadView
{
    NSLog(@"ERASE");
}

@end
