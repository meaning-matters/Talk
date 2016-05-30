//
//  SettingsViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import "SettingsViewController.h"
#import "CountriesViewController.h"
#import "PhonesViewController.h"
#import "CallerIdViewController.h"
#import "Settings.h"
#import "NetworkStatus.h"
#import "CountryNames.h"
#import "Strings.h"
#import "BlockAlertView.h"
#import "BlockActionSheet.h"
#import "Common.h"
#import "Skinning.h"
#import "DataManager.h"
#import "PhoneData.h"

// Update reloadSections calls when adding/removing sections.
typedef enum
{
    TableSectionCallback    = 1UL << 0,
    TableSectionCallerId    = 1UL << 1,
    TableSectionHomeCountry = 1UL << 2,
    TableSectionOptions     = 1UL << 3,
    TableSectionAccountData = 1UL << 4,
} TableSections;


@interface SettingsViewController ()
{
    TableSections sections;
    Settings*     settings;
    BOOL          accountDataUpdated;
}

@property (nonatomic, strong) NSIndexPath* countryIndexPath;

@end


@implementation SettingsViewController

#pragma mark - Basic Stuff

- (instancetype)init
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.title = NSLocalizedString(@"Settings", @"Settings tab title");
        // The tabBarItem image must be set in my own NavigationController.

        // Mandatory sections.
        sections |= TableSectionCallback;
        sections |= TableSectionCallerId;
        sections |= TableSectionHomeCountry;
        sections |= TableSectionOptions;
        sections |= TableSectionAccountData;

        settings = [Settings sharedSettings];

        // Force loading the view in order to add the observers.
        self.view ? (void)1 : (void)0;  // The ?: is to avoid compiler warnings only.
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.clearsSelectionOnViewWillAppear = YES;

    [[NSNotificationCenter defaultCenter] addObserverForName:NetworkStatusSimChangedNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification* note)
    {
        [Common reloadSections:TableSectionHomeCountry allSections:sections tableView:self.tableView];
    }];

    // Refresh the Phone or Number names used.
    [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextObjectsDidChangeNotification
                                                      object:[DataManager sharedManager].managedObjectContext
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification* note)
    {
        [Common reloadSections:(TableSectionCallback | TableSectionCallerId)
                   allSections:sections
                     tableView:self.tableView];
    }];

    [settings addObserver:self
               forKeyPath:@"callbackE164"
                  options:NSKeyValueObservingOptionNew
                  context:nil];
    [settings addObserver:self
               forKeyPath:@"callerIdE164"
                  options:NSKeyValueObservingOptionNew
                  context:nil];
    [settings addObserver:self
               forKeyPath:@"homeIsoCountryCode"
                  options:NSKeyValueObservingOptionNew
                  context:nil];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // When there's no longer a SIM supplying country, reset the simIsoCountryCode settings.
    if ([NetworkStatus sharedStatus].simIsoCountryCode == nil && settings.useSimIsoCountryCode == YES)
    {
        settings.useSimIsoCountryCode = NO;
        [self.tableView reloadData];
    }
}


- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    NSUInteger reloadSections = 0;
    
    if ([keyPath isEqualToString:@"callbackE164"])
    {
        reloadSections |= TableSectionCallback;
    }
    else if ([keyPath isEqualToString:@"callerIdE164"])
    {
        reloadSections |= TableSectionCallerId;
    }
    else if ([keyPath isEqualToString:@"homeIsoCountryCode"])
    {
        reloadSections |= TableSectionHomeCountry;
    }
    
    if ([keyPath isEqualToString:@"callbackE164"] || [keyPath isEqualToString:@"callerIdE164"])
    {
        if (accountDataUpdated == NO)
        {
            // To update when provisioned.
            reloadSections |= TableSectionAccountData;
            accountDataUpdated = YES;
        }
    }

    [Common reloadSections:reloadSections allSections:sections tableView:self.tableView];
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
        case TableSectionCallback:
        {
            title = NSLocalizedStringWithDefaultValue(@"Settings:Callback SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Phone You're Called On",
                                                      @"The way calls are being made.");
            break;
        }
        case TableSectionCallerId:
        {
            title = NSLocalizedStringWithDefaultValue(@"Settings:CallerId SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Default Identity",
                                                      @"The way calls are being made.");
            break;
        }
        case TableSectionHomeCountry:
        {
            title = NSLocalizedStringWithDefaultValue(@"Settings:HomeCountry SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Home Country",
                                                      @"Country where user lives (used to interpret dialed phone numbers).");
            break;
        }
        case TableSectionOptions:
        {
            title = NSLocalizedStringWithDefaultValue(@"Settings:Options SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Display Options",
                                                      @"....");
            break;
        }
        case TableSectionAccountData:
        {
            title = NSLocalizedStringWithDefaultValue(@"Settings:AccountData SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Account Data",
                                                      @"Option to reset all app settings & data.");
            break;
        }
    }

    return title;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString* title = nil;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionCallback:
        {
            title = NSLocalizedStringWithDefaultValue(@"Settings:Callback SectionFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"When making a call, you're first called back on this Phone.",
                                                      @"Explanation how Callback setting works\n"
                                                      @"[* lines]");
            break;
        }
        case TableSectionCallerId:
        {
            title = NSLocalizedStringWithDefaultValue(@"Settings:CallerId SectionFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"Used when calling a number from the Keypad, or a contact "
                                                      @"you did not assign a caller ID.",
                                                      @"Explanation how Caller ID setting works\n"
                                                      @"[* lines]");
            break;
        }
        case TableSectionHomeCountry:
        {
            title = NSLocalizedStringWithDefaultValue(@"Settings:HomeCountryInfo SectionFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"Determines how phone numbers without country code are interpreted.",
                                                      @"Explanation what the Home Country setting is doing\n"
                                                      @"[* lines]");
            break;
        }
        case TableSectionOptions:
        {
            title = NSLocalizedStringWithDefaultValue(@"Settings:Options SectionFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"Choose to sort lists of Phones and Numbers by country or name.",
                                                      @"Explanation what the Home Country setting is doing\n"
                                                      @"[* lines]");
            break;
        }
        case TableSectionAccountData:
        {
            title = NSLocalizedStringWithDefaultValue(@"Settings:AccountDataInfoFull SectionFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"With a reset you only lose these Settings and your call Recents. "
                                                      @"You can always restore your account Credit, verified "
                                                      @"Phones, purchased Numbers, and Destinations on other devices.",
                                                      @"Explanation what the Reset setting is doing\n"
                                                      @"[* lines]");
            break;
        }
    }

    return title;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionCallback:
        {
            numberOfRows = 1;
            break;
        }
        case TableSectionCallerId:
        {
            numberOfRows = 2;
            break;
        }
        case TableSectionHomeCountry:
        {
            numberOfRows = ([NetworkStatus sharedStatus].simIsoCountryCode != nil) ? 2 : 1;
            break;
        }
        case TableSectionOptions:
        {
            numberOfRows = 1;
            break;
        }
        case TableSectionAccountData:
        {
            numberOfRows = 2;
            break;
        }
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
    NSString*                headerTitle;
    NSString*                footerTitle;
    NSString*                message;
    NSString*                homeIsoCountryCode = settings.homeIsoCountryCode;
    CallableData*            callable;
    UITableViewCell*         cell = [self.tableView cellForRowAtIndexPath:indexPath];
    PhonesViewController*    phonesViewController;
    CallerIdViewController*  callerIdViewController;
    CountriesViewController* countriesViewController;
    NSManagedObjectContext*  managedObjectContext = [DataManager sharedManager].managedObjectContext;

    switch ([Common nthBitSet:indexPath.section inValue:sections])
    {
        case TableSectionCallback:
        {
            callable    = [[DataManager sharedManager] lookupCallableForE164:settings.callbackE164];
            headerTitle = NSLocalizedStringWithDefaultValue(@"Settings ...", nil, [NSBundle mainBundle],
                                                            @"Select Phone To Be Called On",
                                                            @"[1/4 line larger font].");
            footerTitle = NSLocalizedStringWithDefaultValue(@"Settings ...", nil, [NSBundle mainBundle],
                                                            @"When you initiate a call, you'll be called back "
                                                            @"on the selected number.\n\nTo limit your costs, "
                                                            @"make sure that the NumberBay calling rate to this "
                                                            @"number is low, and also check the extra charges of your "
                                                            @"telephone operator for receiving calls (which can be "
                                                            @"substantial).\n\nIf you can, it's often good to use "
                                                            @"a fixed-line phone, or to use a local SIM from the "
                                                            @"country you're in.\n\nPeople you call will never see "
                                                            @"which number you selected here; unless of course, you "
                                                            @"also select the same number as Caller ID.",
                                                            @"[1/4 line larger font].");
            
            phonesViewController = [[PhonesViewController alloc] initWithManagedObjectContext:managedObjectContext
                                                                                selectedPhone:(PhoneData*)callable
                                                                                   completion:^(PhoneData* selectedPhone)
            {
                settings.callbackE164 = selectedPhone.e164;
                
                cell.detailTextLabel.text = selectedPhone.name;
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            }];
            
            phonesViewController.title       = cell.textLabel.text;
            phonesViewController.headerTitle = headerTitle;
            phonesViewController.footerTitle = footerTitle;
            [self.navigationController pushViewController:phonesViewController animated:YES];
            
            break;
        }
        case TableSectionCallerId:
        {
            callable    = [[DataManager sharedManager] lookupCallableForE164:settings.callerIdE164];
            headerTitle = NSLocalizedStringWithDefaultValue(@"Settings ...", nil, [NSBundle mainBundle],
                                                            @"Select Default Caller ID",
                                                            @"[1/4 line larger font].");
            footerTitle = NSLocalizedStringWithDefaultValue(@"Settings ...", nil, [NSBundle mainBundle],
                                                            @"People you call will see the selected number, but "
                                                            @"only when the Show My Caller ID setting is on.\n\n"
                                                            @"Add as many as you like. It can be handy to have an "
                                                            @"extensive list to select from.",
                                                            @"[1/4 line larger font].");
            
            callerIdViewController = [[CallerIdViewController alloc] initWithManagedObjectContext:nil
                                                                                         callerId:nil
                                                                                 selectedCallable:callable
                                                                                        contactId:nil
                                                                                       completion:^(CallableData* selectedCallable,
                                                                                                    BOOL          showCallerId)
            {
                settings.showCallerId = showCallerId;

                settings.callerIdE164 = selectedCallable.e164;

                cell.detailTextLabel.text = selectedCallable.name;
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            }];
            
            [self.navigationController pushViewController:callerIdViewController animated:YES];
            break;
        }
        case TableSectionHomeCountry:
        {
            self.countryIndexPath = indexPath;
            countriesViewController = [[CountriesViewController alloc] initWithIsoCountryCode:homeIsoCountryCode
                                                                                        title:[Strings homeCountryString]
                                                                                   completion:^(BOOL      cancelled,
                                                                                                NSString* isoCountryCode)
            {
                if (cancelled == NO)
                {
                    settings.homeIsoCountryCode = isoCountryCode;

                    // Set the cell to prevent quick update right after animations.
                    cell.imageView.image      = [UIImage imageNamed:settings.homeIsoCountryCode];
                    cell.detailTextLabel.text = [[CountryNames sharedNames] nameForIsoCountryCode:settings.homeIsoCountryCode];
                }
            }];
            
            [self.navigationController pushViewController:countriesViewController animated:YES];
            break;
        }
        case TableSectionAccountData:
        {
            if (settings.haveAccount == NO && indexPath.row == 0)
            {
                [Common showGetStartedViewController];
            }
            else if (settings.haveAccount == YES && indexPath.row == 0)
            {
                static UIActivityIndicatorView* indicator;

                if (indicator == nil)
                {
                    indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                    cell.accessoryView = indicator;
                    [indicator startAnimating];

                    [[DataManager sharedManager] synchronizeWithServer:^(NSError* error)
                    {
                        [indicator stopAnimating];
                        cell.accessoryView = nil;
                        indicator = nil;
                    }];
                }

                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
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

                [BlockActionSheet showActionSheetWithTitle:message
                                                completion:^(BOOL cancelled, BOOL destruct, NSInteger buttonIndex)
                {
                    if (destruct == YES)
                    {
                        [[AppDelegate appDelegate] resetAll];
                        
                        int count = [Common bitsSetCount:sections];
                        [self.tableView beginUpdates];
                        [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, count)]
                                      withRowAnimation:UITableViewRowAnimationFade];
                        [self.tableView endUpdates];
                        accountDataUpdated = NO;
                    }
                }
                                         cancelButtonTitle:[Strings cancelString]
                                    destructiveButtonTitle:title
                                         otherButtonTitles:nil];
            }
            
            break;
        }
        default:
        {
            break;
        }
    }
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    switch ([Common nthBitSet:indexPath.section inValue:sections])
    {
        case TableSectionCallback:
        {
            cell = [self callbackCellForRowAtIndexPath:indexPath];
            break;
        }
        case TableSectionCallerId:
        {
            cell = [self callerIdCellForRowAtIndexPath:indexPath];
            break;
        }
        case TableSectionHomeCountry:
        {
            cell = [self homeIsoCountryCodeCellForRowAtIndexPath:indexPath];
            break;
        }
        case TableSectionOptions:
        {
            cell = [self optionCellForRowAtIndexPath:indexPath];
            break;
        }
        case TableSectionAccountData:
        {
            cell = [self accountDataCellForRowAtIndexPath:indexPath];
            break;
        }
        default:
        {
            break;
        }
    }

    return cell;
}


- (UITableViewCell*)callbackCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"CallbackCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"CallbackCell"];
        cell.detailTextLabel.textColor = [Skinning valueColor];
    }

    cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Settings Callback Number", nil,
                                                            [NSBundle mainBundle], @"Callback",
                                                            @"Phone number on which user is reachable.\n"
                                                            @"[1/2 line, abbreviated: Called].");
    
    CallableData* callable = [[DataManager sharedManager] lookupCallableForE164:settings.callbackE164];
    cell.detailTextLabel.text = (callable != nil) ? callable.name : @"";

    cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;

    return cell;
}


- (UITableViewCell*)callerIdCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    UISwitch*        switchView;

    if (indexPath.row == 0)
    {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"CallerIDCell"];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"CallerIDCell"];
            cell.detailTextLabel.textColor = [Skinning valueColor];
        }
        
        cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Setting Shown Number Format", nil,
                                                                [NSBundle mainBundle], @"Caller ID",
                                                                @"Format string showing shown number.\n"
                                                                @"[1 line].");
        CallableData* callable = [[DataManager sharedManager] lookupCallableForE164:settings.callerIdE164];
        if (callable != nil)
        {
            if (settings.showCallerId)
            {
                cell.detailTextLabel.attributedText = nil;
                cell.detailTextLabel.text = callable.name;
            }
            else
            {
                NSDictionary*       attributes = @{NSStrikethroughStyleAttributeName : @(NSUnderlineStyleSingle)};
                NSAttributedString* nameString = [[NSAttributedString alloc] initWithString:callable.name attributes:attributes];
                cell.detailTextLabel.attributedText = nameString;
            }
        }
        else
        {
            cell.detailTextLabel.text = @"";
        }
        
        cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    else
    {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"SwitchCell"];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"SwitchCell"];
            switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
            switchView.onTintColor = [Skinning onTintColor];
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
    }
    
    return cell;
}


- (UITableViewCell*)homeIsoCountryCodeCellForRowAtIndexPath:(NSIndexPath*)indexPath
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
            switchView.onTintColor = [Skinning onTintColor];
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
        switchView.on = settings.useSimIsoCountryCode;

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
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"CountryCell"];
        }

        if (settings.homeIsoCountryCode != nil)
        {
            // Note: This is also done in CountriesViewController (to update the
            //       selected cell before animation).  So pay a visit there when
            //       changing this.
            cell.imageView.image      = [UIImage imageNamed:settings.homeIsoCountryCode];
            cell.detailTextLabel.text = [[CountryNames sharedNames] nameForIsoCountryCode:settings.homeIsoCountryCode];
        }
        else
        {
            cell.imageView.image = nil;
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Settings:NoCountryName CellText", nil,
                                                                    [NSBundle mainBundle], @"No Country Selected",
                                                                    @"Table cell text, when user not selected home country yet\n"
                                                                    @"[1 line - abbreviated: 'Not Selected'");
        }

        if ([NetworkStatus sharedStatus].simIsoCountryCode != nil && settings.useSimIsoCountryCode)
        {
            cell.accessoryType  = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        else
        {
            cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
    }
    
    return cell;
}


- (UITableViewCell*)optionCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;
    UISegmentedControl* segmentedControl;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"SortOrderCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"SortOrderCell"];
        NSString* byCountries = NSLocalizedStringWithDefaultValue(@"Numbers SortByCountries", nil,
                                                                  [NSBundle mainBundle], @"Country",
                                                                  @"\n"
                                                                  @"[1/4 line larger font].");
        NSString* byNames     = NSLocalizedStringWithDefaultValue(@"Numbers SortByName", nil,
                                                                  [NSBundle mainBundle], @"Name",
                                                                  @"\n"
                                                                  @"[1/4 line larger font].");
        segmentedControl = [[UISegmentedControl alloc] initWithItems:@[byCountries, byNames]];
        segmentedControl.selectedSegmentIndex = [Settings sharedSettings].sortSegment;
        [segmentedControl addTarget:self
                             action:@selector(sortOrderChangedAction:)
                   forControlEvents:UIControlEventValueChanged];
        
        cell.accessoryView = segmentedControl;
    }
    else
    {
        segmentedControl = (UISegmentedControl*)cell.accessoryView;
    }
    
    cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Settings:Sort CellText", nil,
                                                            [NSBundle mainBundle], @"Sort By",
                                                            @"Title of switch if people called see my number\n"
                                                            @"[2/3 line - abbreviated: 'Show Caller ID', use "
                                                            @"exact same term as in iOS].");
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
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
                                                                @"[....");
        cell.textLabel.textColor = [Skinning tintColor];
    }
    else if (settings.haveAccount == YES && indexPath.row == 0)
    {
        cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Settings:Synchronize CellText", nil,
                                                                [NSBundle mainBundle], @"Synchronize With Server",
                                                                @"Title of table cell for getting an account\n"
                                                                @"....");
        cell.textLabel.textColor = [Skinning tintColor];
    }
    else
    {
        cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Settings:Reset CellText", nil,
                                                                [NSBundle mainBundle], @"Reset All",
                                                                @"Title of table cell for resetting all user data\n"
                                                                @"...].");
        cell.textLabel.textColor = [Skinning deleteTintColor];
    }

    cell.accessoryType  = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;

    return cell;
}


#pragma mark - UI Actions

- (void)readFromSimSwitchAction:(id)sender
{
    settings.useSimIsoCountryCode = ((UISwitch*)sender).on;
    if (settings.useSimIsoCountryCode)
    {
        settings.homeIsoCountryCode = [NetworkStatus sharedStatus].simIsoCountryCode;
    }

    [self.tableView beginUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:[Common nOfBit:TableSectionHomeCountry inValue:sections]]
                  withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}


- (void)showCallerIdSwitchAction:(id)sender
{
    settings.showCallerId = ((UISwitch*)sender).on;
    
    NSArray* indexPaths = @[[NSIndexPath indexPathForItem:0
                                                inSection:[Common nOfBit:TableSectionCallerId inValue:sections]]];
    
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
}


#pragma Helpers

- (void)sortOrderChangedAction:(UISegmentedControl*)segmentedControl
{
    [Settings sharedSettings].sortSegment = segmentedControl.selectedSegmentIndex;
}

@end
