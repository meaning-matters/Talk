//
//  SettingsViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "SettingsViewController.h"
#import "CountriesViewController.h"
#import "PhonesViewController.h"
#import "Settings.h"
#import "NetworkStatus.h"
#import "CountryNames.h"
#import "Strings.h"
#import "BlockAlertView.h"
#import "Common.h"
#import "Skinning.h"


// Update reloadSections calls when adding/removing sections.
typedef enum
{
    TableSectionCallMode    = 1UL << 0,
    TableSectionHomeCountry = 1UL << 1,
    TableSectionCallOptions = 1UL << 2,
    TableSectionAccountData = 1UL << 3,
} TableSections;


@interface SettingsViewController ()
{
    TableSections sections;
    Settings*     settings;
}

@end


@implementation SettingsViewController

#pragma mark - Basic Stuff

- (instancetype)init
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.title = NSLocalizedString(@"Settings", @"Settings tab title");
        self.tabBarItem.image = [UIImage imageNamed:@"SettingsTab.png"];

        // Mandatory sections.
        sections |= TableSectionCallMode;
        sections |= TableSectionHomeCountry;
        sections |= TableSectionAccountData;

        // Optional sections.
        sections |= HAS_VOIP ? TableSectionCallOptions : 0;

        settings = [Settings sharedSettings];

        self.clearsSelectionOnViewWillAppear = YES;
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserverForName:NetworkStatusSimChangedNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification* note)
    {
        NSMutableIndexSet*  indexSet = [NSMutableIndexSet indexSet];
        [indexSet addIndex:[Common bitIndex:TableSectionHomeCountry]];
        [indexSet addIndex:[Common bitIndex:TableSectionCallOptions]];
        
        [self.tableView beginUpdates];
        [self.tableView reloadSections:indexSet
                      withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    }];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    BOOL pushed = [self isMovingToParentViewController];
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:!pushed];

    // When there's no longer a SIM supplying country, reset the homeCountryFromSim settings.
    if ([NetworkStatus sharedStatus].simIsoCountryCode == nil && settings.homeCountryFromSim == YES)
    {
        settings.homeCountryFromSim = NO;
        [self.tableView reloadData];
    }
}


#pragma mark - Table View Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return [Common bitsSetCount:sections];
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* title = nil;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionCallMode:
            title = NSLocalizedStringWithDefaultValue(@"Settings:CallMode SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Call Mode",
                                                      @"The way calls are being made.");
            break;

        case TableSectionHomeCountry:
            title = NSLocalizedStringWithDefaultValue(@"Settings:HomeCountry SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Home Country",
                                                      @"Country where user lives (used to interpret dialed phone numbers).");
            break;

        case TableSectionCallOptions:
            title = NSLocalizedStringWithDefaultValue(@"Settings:CallOptions SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Call Options",
                                                      @"Various options related to making calls.");
            break;

        case TableSectionAccountData:
            title = NSLocalizedStringWithDefaultValue(@"Settings:AccountData SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Account Data",
                                                      @"Option to reset all app settings & data.");
            break;
    }

    return title;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString* title = nil;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionCallMode:
#if HAS_VOIP
            title = NSLocalizedStringWithDefaultValue(@"Settings:CallModeInfo SectionFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"In Callback Mode, our server first calls your Called Back number.  "
                                                      @"Then, when you accept that call, the person you're tying to "
                                                      @"reach is being called; the Caller ID is used as caller ID.",
                                                      @"Explanation what Call Mode setting is doing\n"
                                                      @"[* lines]");
#else
            title = NSLocalizedStringWithDefaultValue(@"Settings:CallbackInfo SectionFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"Our server first calls the Called Back number.  Then, when you "
                                                      @"accept that call, the party you're tying to reach is being "
                                                      @"called, and is show My Caller ID (when the Show My Caller "
                                                      @"ID setting is on).",
                                                      @"Explanation how Callback settings work\n"
                                                      @"[* lines]");
#endif
            break;

        case TableSectionHomeCountry:
            title = NSLocalizedStringWithDefaultValue(@"Settings:HomeCountryInfo SectionFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"Determines how phone numbers without country code are interpreted.",
                                                      @"Explanation what the Home Country setting is doing\n"
                                                      @"[* lines]");
            break;

        case TableSectionAccountData:
            title = NSLocalizedStringWithDefaultValue(@"Settings:AccountDataInfo SectionFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"After a reset, you can restore your account, purchased "
                                                      @"numbers, forwardings, and credit on any device.",
                                                      @"Explanation what the Reset setting is doing\n"
                                                      @"[* lines]");
            break;
    }

    return title;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionCallMode:
            numberOfRows = HAS_VOIP ? (settings.callbackMode ? 3 : 1) : 3;
            break;

        case TableSectionHomeCountry:
            numberOfRows = ([NetworkStatus sharedStatus].simIsoCountryCode != nil) ? 2 : 1;
            break;

        case TableSectionCallOptions:
            numberOfRows = [NetworkStatus sharedStatus].simAvailable ? 2 : 1;
            break;

        case TableSectionAccountData:
            numberOfRows = settings.haveAccount ? 1 : 2;
            break;
    }

    return numberOfRows;
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    if ([self.tableView cellForRowAtIndexPath:indexPath].selectionStyle == UITableViewCellSelectionStyleNone)
    {
        return;
    }

    NSString*                title;
    NSString*                message;
    NSString*                homeCountry = settings.homeCountry;
    PhonesViewController*   phonesViewController;
    CountriesViewController* countriesViewController;

    switch ([Common nthBitSet:indexPath.section inValue:sections])
    {
        case TableSectionCallMode:
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

            if (indexPath.row == 1 - !HAS_VOIP)
            {
                phonesViewController = [[PhonesViewController alloc] init];
                [self.navigationController pushViewController:phonesViewController animated:YES];
                break;

                __block BlockAlertView*  alert;
                NSString*                title;
                NSString*                message;
                PhoneNumber*             callbackPhoneNumber = [[PhoneNumber alloc] initWithNumber:settings.callbackE164];

                title   = NSLocalizedStringWithDefaultValue(@"Setting EnterNumberTitle", nil,
                                                            [NSBundle mainBundle], @"Enter Called Number",
                                                            @"Title asking user to enter their phone number.\n"
                                                            @"[iOS alert title size].");
                message = NSLocalizedStringWithDefaultValue(@"Setting VerifyCancelMessage", nil,
                                                            [NSBundle mainBundle],
                                                            @"Enter a number you own, on which you will be called back.",
                                                            @"Message explaining about the phone number they need to enter.\n"
                                                            @"[iOS alert message size]");
                alert   = [BlockAlertView showPhoneNumberAlertViewWithTitle:title
                                                                    message:message
                                                                phoneNumber:callbackPhoneNumber
                                                                 completion:^(BOOL         cancelled,
                                                                              PhoneNumber* phoneNumber)
                {
                    if (cancelled == NO)
                    {
                        if ([phoneNumber isValid])
                        {
                            settings.callbackE164 = [phoneNumber e164Format];

                            [self reloadCallModeSection];
                        }
                        else
                        {
                            NSString* title;
                            NSString* message;

                            title   = NSLocalizedStringWithDefaultValue(@"Provisioning VerifyInvalidTitle", nil,
                                                                        [NSBundle mainBundle], @"Invalid Number",
                                                                        @"Phone number is not correct.\n"
                                                                        @"[iOS alert title size].");
                            message = NSLocalizedStringWithDefaultValue(@"Provisioning VerifyInvalidMessage", nil,
                                                                        [NSBundle mainBundle],
                                                                        @"The phone number you entered is invalid, "
                                                                        @"please correct.",
                                                                        @"Alert message that entered phone number is invalid.\n"
                                                                        @"[iOS alert message size]");
                            [BlockAlertView showAlertViewWithTitle:title
                                                           message:message
                                                        completion:nil
                                                 cancelButtonTitle:[Strings closeString]
                                                 otherButtonTitles:nil];
                        }
                    }
                }
                                                          cancelButtonTitle:[Strings cancelString]
                                                          otherButtonTitles:[Strings okString], nil];
            }
            else if (indexPath.row == 2 - !HAS_VOIP)
            {
                __block BlockAlertView*  alert;
                NSString*                title;
                NSString*                message;
                PhoneNumber*             callerIdPhoneNumber = [[PhoneNumber alloc] initWithNumber:settings.callerIdE164];

                title   = NSLocalizedStringWithDefaultValue(@"Setting EnterNumberTitle", nil,
                                                            [NSBundle mainBundle], @"Enter Shown Number",
                                                            @"Title asking user to enter their phone number.\n"
                                                            @"[iOS alert title size].");
                message = NSLocalizedStringWithDefaultValue(@"Setting VerifyCancelMessage", nil,
                                                            [NSBundle mainBundle],
                                                            @"Enter a number you own, that will be shown as caller ID "
                                                            @"to the person you're trying reach.",
                                                            @"Message explaining about the phone number they need to enter.\n"
                                                            @"[iOS alert message size]");
                alert   = [BlockAlertView showPhoneNumberAlertViewWithTitle:title
                                                                    message:message
                                                                phoneNumber:callerIdPhoneNumber
                                                                 completion:^(BOOL         cancelled,
                                                                              PhoneNumber* phoneNumber)
                {
                    if (cancelled == NO)
                    {
                        if ([phoneNumber isValid])
                        {
                            settings.callerIdE164 = [phoneNumber e164Format];

                            [self reloadCallModeSection];
                        }
                        else
                        {
                            NSString* title;
                            NSString* message;

                            title   = NSLocalizedStringWithDefaultValue(@"Provisioning VerifyInvalidTitle", nil,
                                                                        [NSBundle mainBundle], @"Invalid Number",
                                                                        @"Phone number is not correct.\n"
                                                                        @"[iOS alert title size].");
                            message = NSLocalizedStringWithDefaultValue(@"Provisioning VerifyInvalidMessage", nil,
                                                                        [NSBundle mainBundle],
                                                                        @"The phone number you entered is invalid, "
                                                                        @"please correct.",
                                                                        @"Alert message that entered phone number is invalid.\n"
                                                                        @"[iOS alert message size]");
                            [BlockAlertView showAlertViewWithTitle:title
                                                           message:message
                                                        completion:nil
                                                 cancelButtonTitle:[Strings closeString]
                                                 otherButtonTitles:nil];
                        }
                    }
                }
                                                          cancelButtonTitle:[Strings cancelString]
                                                          otherButtonTitles:[Strings okString], nil];
            }
            break;

        case TableSectionHomeCountry:
        {
            countriesViewController = [[CountriesViewController alloc] initWithIsoCountryCode:homeCountry
                                                                                   completion:^(BOOL      cancelled,
                                                                                                NSString* isoCountryCode)
            {
                if (cancelled == NO)
                {
                    settings.homeCountry = isoCountryCode;

                    // Set the cell to prevent quick update right after animations.
                    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
                    cell.imageView.image  = [UIImage imageNamed:settings.homeCountry];
                    cell.textLabel.text   = [[CountryNames sharedNames] nameForIsoCountryCode:settings.homeCountry];
                }
            }];
            
            [self.navigationController pushViewController:countriesViewController animated:YES];
            break;
        }

        case TableSectionAccountData:
            if (settings.haveAccount == NO && indexPath.row == 0)
            {
                [Common showProvisioningViewController];
            }
            else
            {
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                
                title   = NSLocalizedStringWithDefaultValue(@"Settings:Reset ResetTitle", nil,
                                                            [NSBundle mainBundle], @"Reset All",
                                                            @"Alert title informing about resetting all user data\n"
                                                            @"[iOS alert title size].");

                message = NSLocalizedStringWithDefaultValue(@"Settings:Reset ResetMessage", nil,
                                                            [NSBundle mainBundle],
                                                            @"Are you sure you want to wipe your account and data "
                                                            @"from this device?",
                                                            @"Alert message informing about resetting all user data\n"
                                                            @"[iOS alert message size]");

                {   // Prevents "Switch case is in protected scope” compiler error at default:.
                    [BlockAlertView showAlertViewWithTitle:title
                                                   message:message
                                                completion:^(BOOL cancelled, NSInteger buttonIndex)
                    {
                        if (buttonIndex == 1)
                        {
                            [[AppDelegate appDelegate] resetAll];
                            
                            [self.tableView beginUpdates];
                            [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)]
                                          withRowAnimation:UITableViewRowAnimationFade];
                            [self.tableView endUpdates];
                        }
                    }
                                         cancelButtonTitle:[Strings cancelString]
                                         otherButtonTitles:[Strings okString], nil];
                }
            }
            break;

        default:
            break;
    }
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;

    switch ([Common nthBitSet:indexPath.section inValue:sections])
    {
        case TableSectionCallMode:
            cell = [self callModeCellForRowAtIndexPath:indexPath];
            break;

        case TableSectionHomeCountry:
            cell = [self homeCountryCellForRowAtIndexPath:indexPath];
            break;

        case TableSectionCallOptions:
            cell = [self callOptionsCellForRowAtIndexPath:indexPath];
            break;

        case TableSectionAccountData:
            cell = [self accountDataCellForRowAtIndexPath:indexPath];
            break;
            
        default:
            break;
    }

    return cell;
}


- (UITableViewCell*)homeCountryCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    UISwitch*        switchView;

    if ([NetworkStatus sharedStatus].simIsoCountryCode != nil && indexPath.row == 0)
    {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"SwitchCell"];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"SwitchCell"];
            switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.accessoryView = switchView;
        }
        else
        {
            switchView = (UISwitch*)cell.accessoryView;
        }

        cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Settings:ReadFromSim CellText", nil,
                                                                [NSBundle mainBundle], @"Read From SIM",
                                                                @"Title of switch if home country must be read from SIM card\n"
                                                                @"[2/3 line - abbreviated: 'From SIM'].");
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        switchView.on = settings.homeCountryFromSim;

        [switchView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [switchView addTarget:self action:@selector(readFromSimSwitchAction:)
             forControlEvents:UIControlEventValueChanged];
    }

    if (([NetworkStatus sharedStatus].simIsoCountryCode != nil && indexPath.row == 1) ||
        [NetworkStatus sharedStatus].simIsoCountryCode == nil)
    {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"CountryCell"];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"DefaultCell"];
        }

        if (settings.homeCountry != nil)
        {
            // Note: This is also done in CountriesViewController (to update the
            //       selected cell before animation).  So pay a visit there when
            //       changing this.
            cell.imageView.image = [UIImage imageNamed:settings.homeCountry];
            cell.detailTextLabel.text = [[CountryNames sharedNames] nameForIsoCountryCode:settings.homeCountry];
        }
        else
        {
            cell.imageView.image = nil;
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Settings:NoCountryName CellText", nil,
                                                                    [NSBundle mainBundle], @"No Country Selected",
                                                                    @"Table cell text, when user not selected home country yet\n"
                                                                    @"[1 line - abbreviated: 'Not Selected'");
        }
        
        if ([NetworkStatus sharedStatus].simIsoCountryCode != nil && settings.homeCountryFromSim)
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        else
        {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
    }

    return cell;
}


- (UITableViewCell*)callModeCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    UISwitch*        switchView;

    if (indexPath.row == 0 - !HAS_VOIP)
    {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"CallModeSwitchCell"];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"CallModeSwitchCell"];
            switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.accessoryView = switchView;
        }
        else
        {
            switchView = (UISwitch*)cell.accessoryView;
        }

        cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Settings:CallbackMode CellText", nil,
                                                                [NSBundle mainBundle], @"Callback Mode",
                                                                @"Title of switch if app is in 'callback mode'\n"
                                                                @"[2/3 line].");
        cell.selectionStyle    = UITableViewCellSelectionStyleNone;
        switchView.on          = settings.callbackMode;
        switchView.onTintColor = [Skinning callbackModeTintColor];

        [switchView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [switchView addTarget:self
                       action:@selector(callbackModeSwitchAction:)
             forControlEvents:UIControlEventValueChanged];
    }
    else if (indexPath.row == 1 - !HAS_VOIP)
    {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"CallerCell"];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"CallerCell"];
        }

        PhoneNumber* phoneNumber  = [[PhoneNumber alloc] initWithNumber:settings.callbackE164];
        cell.textLabel.text       = NSLocalizedStringWithDefaultValue(@"Settings Called Back Number", nil,
                                                                      [NSBundle mainBundle], @"Called Back",
                                                                      @"Phone number on which user is reachable.\n"
                                                                      @"[1/2 line, abbreviated: Called].");
        cell.detailTextLabel.text = [phoneNumber internationalFormat];
        cell.accessoryType        = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle       = UITableViewCellSelectionStyleDefault;
    }
    else if (indexPath.row == 2 - !HAS_VOIP)
    {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"CallerIDCell"];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"CallerIDCell"];
        }

        PhoneNumber* phoneNumber  = [[PhoneNumber alloc] initWithNumber:settings.callerIdE164];
        cell.textLabel.text       = NSLocalizedStringWithDefaultValue(@"Setting Shown Number Format", nil,
                                                                      [NSBundle mainBundle], @"Caller ID",
                                                                      @"Format string showing shown number.\n"
                                                                      @"[1 line].");
        cell.detailTextLabel.text = [phoneNumber internationalFormat];
        cell.accessoryType        = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle       = UITableViewCellSelectionStyleDefault;
    }
    else if (indexPath.row == 2)
    {
        cell = [self showCallerIdCell];
    }

    return cell;
}


- (UITableViewCell*)callOptionsCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    if (indexPath.row == 0)
    {
        cell = [self showCallerIdCell];
    }
    
    if (indexPath.row == 1)
    {
        UISwitch* switchView;

        cell = [self.tableView dequeueReusableCellWithIdentifier:@"SwitchCell"];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"SwitchCell"];
            switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.accessoryView = switchView;
        }
        else
        {
            switchView = (UISwitch*)cell.accessoryView;
        }

        cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Settings:AllowDataCalls CellText", nil,
                                                                [NSBundle mainBundle], @"Cellular Data Calls",
                                                                @"Title of switch if calls over cellular data "
                                                                @"(3G/EDGE/...) are allowed\n"
                                                                @"[2/3 line - abbreviated: 'Data Calls'].");
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        switchView.on = settings.allowCellularDataCalls;

        [switchView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [switchView addTarget:self
                       action:@selector(allowDataCallsSwitchAction:)
             forControlEvents:UIControlEventValueChanged];
    }

    return cell;
}


- (UITableViewCell*)showCallerIdCell
{
    UITableViewCell* cell;
    UISwitch*        switchView;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"SwitchCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"SwitchCell"];
        switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
        cell.accessoryView = switchView;
    }
    else
    {
        switchView = (UISwitch*)cell.accessoryView;
    }

    cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Settings:ShowCallId CellText", nil,
                                                            [NSBundle mainBundle], @"Show My Caller ID",
                                                            @"Title of switch if people called see my number\n"
                                                            @"[2/3 line - abbreviated: 'Show Caller ID', use "
                                                            @"exact same term as in iOS].");
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    switchView.on = settings.showCallerId;

    [switchView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [switchView addTarget:self
                   action:@selector(showCallerIdSwitchAction:)
         forControlEvents:UIControlEventValueChanged];

    return cell;
}


- (UITableViewCell*)accountDataCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"AccountDataCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"AccountDataCell"];
    }

    if (settings.haveAccount == NO && indexPath.row == 0)
    {
        cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Settings:Get Started CellText", nil,
                                                                [NSBundle mainBundle], @"Get Started",
                                                                @"Title of table cell for getting an account\n"
                                                                @"[2/3 line - abbreviated: 'Reset'].");
    }
    else
    {
        cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Settings:Reset CellText", nil,
                                                                [NSBundle mainBundle], @"Reset All",
                                                                @"Title of table cell for resetting all user data\n"
                                                                @"[2/3 line - abbreviated: 'Reset'].");
    }

    cell.textLabel.textColor = [Skinning tintColor];

    cell.accessoryType  = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;

    return cell;
}


#pragma mark - UI Actions

- (void)readFromSimSwitchAction:(id)sender
{
    settings.homeCountryFromSim = ((UISwitch*)sender).on;
    if (settings.homeCountryFromSim)
    {
        settings.homeCountry = [NetworkStatus sharedStatus].simIsoCountryCode;
    }

    [self.tableView beginUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:[Common bitIndex:TableSectionHomeCountry]]
                  withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}


- (void)callbackModeSwitchAction:(id)sender
{
    settings.callbackMode = ((UISwitch*)sender).on;

    if (settings.callbackMode == YES && settings.callerIdE164.length == 0)
    {
        settings.callerIdE164 = settings.callbackE164;
    }

    [self reloadCallModeSection];
}


- (void)allowDataCalls
{
    [self allowDataCallsSwitchAction:nil];
}


// Can be invoked with sender == nil.
- (void)allowDataCallsSwitchAction:(id)sender
{
    UISwitch*   allowDataCallsSwitch = sender;

    if ((allowDataCallsSwitch.on == YES || allowDataCallsSwitch == nil) &&
        settings.allowCellularDataCalls == NO)
    {
        NSString*   title = NSLocalizedStringWithDefaultValue(@"Settings:AllowDataCalls AllowWarningTitle", nil,
                                                              [NSBundle mainBundle], @"Cellular Data Calls",
                                                              @"Alert title informing about allowing cellular data calls\n"
                                                              @"[iOS alert title size].");

        NSString*   message = NSLocalizedStringWithDefaultValue(@"Settings:AllowDataCalls AllowWaningMessage", nil,
                                                                [NSBundle mainBundle],
                                                                @"Depending on your mobile plan, cellular data calls "
                                                                @"may add a cost from your mobile operator.",
                                                                @"Alert message informing about allowing cellular "
                                                                @"data calls\n"
                                                                @"[iOS alert message size]");

        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
        {
            if (buttonIndex == 1)
            {
                settings.allowCellularDataCalls = YES;
            }
            else
            {
                [allowDataCallsSwitch setOn:NO animated:YES];
            }
        }
                             cancelButtonTitle:[Strings cancelString]
                             otherButtonTitles:[Strings okString], nil];
    }
    else
    {
        settings.allowCellularDataCalls = NO;
    }
}


- (void)showCallerIdSwitchAction:(id)sender
{
    settings.showCallerId = ((UISwitch*)sender).on;
}


#pragma mark - Helpers

- (void)reloadCallModeSection
{
    NSUInteger index = [Common nOfBit:TableSectionCallMode inValue:sections];
    [self.tableView beginUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:index]
                  withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}

@end
