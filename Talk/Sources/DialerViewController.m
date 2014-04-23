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
#import "BlockActionSheet.h"
#import "Strings.h"
#import "NBPersonViewController.h"
#import "Skinning.h"


@interface DialerViewController () <NumberLabelDelegate, NBNewPersonViewControllerDelegate>
{
    PhoneNumber* phoneNumber;    // Holds the current number on screen.
    NSString*    contactId;
    BOOL         contactIdUpdated;
}

@end


@implementation DialerViewController 

@synthesize keypadView  = _keypadView;

- (instancetype)init
{
    if (self = [super initWithNibName:@"DialerView" bundle:nil])
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;

        self.title = NSLocalizedString(@"Dialer", @"Dialer tab title");
        self.tabBarItem.image = [UIImage imageNamed:@"DialerTab.png"];

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

    self.numberLabel.font      = [Common phoneFontOfSize:38];
    self.numberLabel.textColor = [Skinning tintColor];
    self.numberLabel.hasPaste  = YES;
    self.numberLabel.delegate  = self;

    self.keypadView.delegate = self;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // We don't want navigation bar when dialer is on main tabs (i.e., not on More).
    BOOL hidden = (self.navigationController != self.tabBarController.moreNavigationController);
    self.navigationController.navigationBar.hidden = hidden;

    // This will clear the field when coming back from call.
    [self update];

    [[DtmfPlayer sharedPlayer] startKeepAlive]; // See DtmfPlayer.m why this is needed.
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self.view setNeedsLayout];
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
    // The exception in Y values for 'regular tab' has to do with iOS 7 peculiarities.
    switch ((int)self.view.frame.size.height)
    {
        case 367:   // 320x480 screen, More tab.
            [Common setY:2        ofView:self.infoLabel];
            [Common setY:10       ofView:self.brandingImageView];
            [Common setY:24       ofView:self.numberLabel];
            [Common setY:64       ofView:self.nameLabel];
            [Common setY:91       ofView:self.keypadView];
            [Common setHeight:275 ofView:self.keypadView];
            break;

        case 347:   // 320x480 screen, More tab, with in-call iOS flasher at top.
            [Common setY:2        ofView:self.infoLabel];
            [Common setY:10       ofView:self.brandingImageView];
            [Common setY:24       ofView:self.numberLabel];
            [Common setY:64       ofView:self.nameLabel];
            [Common setY:91       ofView:self.keypadView];
            [Common setHeight:255 ofView:self.keypadView];
            break;

        case 431:   // 320x480 screen, regular tab.
            [Common setY:22       ofView:self.infoLabel];
            [Common setY:30       ofView:self.brandingImageView];
            [Common setY:44       ofView:self.numberLabel];
            [Common setY:84       ofView:self.nameLabel];
            [Common setY:111      ofView:self.keypadView];
            [Common setHeight:320 ofView:self.keypadView];
            break;

        case 311:   // 320x480 screen, regular tab, with in-call iOS flasher at top.
            [Common setY:22       ofView:self.infoLabel];
            [Common setY:30       ofView:self.brandingImageView];
            [Common setY:44       ofView:self.numberLabel];
            [Common setY:84       ofView:self.nameLabel];
            [Common setY:111      ofView:self.keypadView];
            [Common setHeight:300 ofView:self.keypadView];
            break;

        case 455:   // 320x568 screen, More tab.
            [Common setY:7        ofView:self.infoLabel];
            [Common setY:15       ofView:self.brandingImageView];
            [Common setY:33       ofView:self.numberLabel];
            [Common setY:77       ofView:self.nameLabel];
            [Common setY:110      ofView:self.keypadView];
            [Common setHeight:345 ofView:self.keypadView];
            break;

        case 435:   // 320x568 screen, More tab, with in-call iOS flasher at top.
            [Common setY:7        ofView:self.infoLabel];
            [Common setY:15       ofView:self.brandingImageView];
            [Common setY:33       ofView:self.numberLabel];
            [Common setY:77       ofView:self.nameLabel];
            [Common setY:110      ofView:self.keypadView];
            [Common setHeight:325 ofView:self.keypadView];
            break;

        case 519:   // 320x568 screen, regular tab.
            [Common setY:26       ofView:self.infoLabel];
            [Common setY:34       ofView:self.brandingImageView];
            [Common setY:52       ofView:self.numberLabel];
            [Common setY:96       ofView:self.nameLabel];
            [Common setY:128      ofView:self.keypadView];
            [Common setHeight:390 ofView:self.keypadView];
            break;

        case 499:   // 320x568 screen, regular tab, with in-call iOS flasher at top.
            [Common setY:26       ofView:self.infoLabel];
            [Common setY:34       ofView:self.brandingImageView];
            [Common setY:52       ofView:self.numberLabel];
            [Common setY:106      ofView:self.nameLabel];
            [Common setY:128      ofView:self.keypadView];
            [Common setHeight:370 ofView:self.keypadView];
            break;
    }
}


#pragma mark - Utility Methods

- (void)updateReachable
{
    BOOL haveAccount   = [Settings sharedSettings].haveAccount;
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

    // Only search for number when valid.
    if (phoneNumber.isValid)
    {
        contactIdUpdated = NO;
        contactId        = nil;
        [[AppDelegate appDelegate] findContactsHavingNumber:[[phoneNumber nationalFormat] substringFromIndex:1]
                                                 completion:^(NSArray* contactIds)
        {
            contactIdUpdated = YES;
            if (contactIds.count > 0)
            {
                contactId = contactIds[0];
                self.nameLabel.text = [[AppDelegate appDelegate] contactNameForId:contactId];
            }
            else
            {
                self.nameLabel.text = @"";
            }
        }];
    }
    else
    {
        self.nameLabel.text = @"";
    }
}


- (NBContact*)createContact
{
    ABRecordRef contactRef = ABPersonCreate();

    ABMutableMultiValueRef numberMulti = ABMultiValueCreateMutable(kABMultiStringPropertyType);
    ABMultiValueAddValueAndLabel(numberMulti, (__bridge CFTypeRef)self.numberLabel.text, kABOtherLabel, NULL);
    ABRecordSetValue(contactRef, kABPersonPhoneProperty, numberMulti, nil);

    NBContact* contact = [[NBContact alloc] initWithContact:contactRef];

    return contact;
}


- (void)makeCallWithContactId:(NSString*)contactId
{
    NSString* identity = [Settings sharedSettings].callerIdE164; //### Select identity.
    Call*     call     = [[CallManager sharedManager] callPhoneNumber:phoneNumber fromIdentity:identity contactId:contactId];

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


#pragma mark - KeypadView Delegate

- (void)keypadView:(KeypadView*)keypadView pressedDigitKey:(KeypadKey)key
{
    phoneNumber.number = [NSString stringWithFormat:@"%@%c", phoneNumber.number, key];
    [self update];

    [[DtmfPlayer sharedPlayer] playCharacter:key atVolume:0.02f];
}


- (void)keypadViewPressedOptionKey:(KeypadView*)keypadView
{
    if (self.numberLabel.text.length == 0)
    {
        return;
    }

    NSString* newTitle = NSLocalizedStringWithDefaultValue(@"Dialer CreateNewContact", nil, [NSBundle mainBundle],
                                                           @"Create New Contact",
                                                           @"....\n"
                                                           @"[iOS alert title size].");

    NSString* addTitle = NSLocalizedStringWithDefaultValue(@"Dialer AddToContact", nil, [NSBundle mainBundle],
                                                           @"Add to Existing Contact",
                                                           @"....\n"
                                                           @"[iOS alert title size].");

    [BlockActionSheet showActionSheetWithTitle:nil
                                    completion:^(BOOL cancelled, BOOL destruct, NSInteger buttonIndex)
    {
        if (buttonIndex == 0)
        {
            NBNewPersonViewController* newPersonViewController = [[NBNewPersonViewController alloc] init];
            [newPersonViewController setContactToMergeWith:[self createContact]];

            [newPersonViewController setANewPersonViewDelegate:self];

            UINavigationController* navigationController;
            navigationController = [[UINavigationController alloc] initWithRootViewController:newPersonViewController];
            [self presentViewController:navigationController animated:YES completion:nil];
        }
        else if (buttonIndex == 1)
        {
            NBPeopleListViewController* listViewController = [[NBPeopleListViewController alloc] init];
            [listViewController setContactToMergeWith:[self createContact]];
            [listViewController setANewPersonViewDelegate:self];

            UINavigationController* navigationController;
            navigationController = [[NBPeoplePickerNavigationController alloc] initWithRootViewController:listViewController];
            [self presentViewController:navigationController animated:YES completion:nil];
        }
    }
                             cancelButtonTitle:[Strings cancelString]
                        destructiveButtonTitle:nil
                             otherButtonTitles:newTitle, addTitle, nil];
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
        if (contactIdUpdated == NO)
        {
            // Looking up contact while entering number is not finished yet, start a new search.
            // We should not get here very often.
            [[AppDelegate appDelegate] findContactsHavingNumber:phoneNumber.number completion:^(NSArray* contactIds)
            {
                if (contactIds.count > 0)
                {
                    [self makeCallWithContactId:contactIds[0]];
                }
                else
                {
                    [self makeCallWithContactId:nil];
                }
            }];
        }
        else
        {
            [self makeCallWithContactId:contactId];
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


#pragma mark - NewPersonViewController Delegate

- (void)newPersonViewController:(NBNewPersonViewController*)newPersonViewController
       didCompleteWithNewPerson:(ABRecordRef)person
{

}

@end
