//
//  SettingsViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "SettingsViewController.h"
#import "CountriesViewController.h"
#import "Settings.h"
#import "NetworkStatus.h"
#import "CountryNames.h"
#import "CommonStrings.h"
#import "BlockAlertView.h"


typedef enum
{
    TableSectionHomeCountry,
    TableSectionCallOptions,
    TableSectionNumber          // Number of table sections.
} TableSections;


@implementation SettingsViewController

#pragma mark - Basic Stuff

- (id)init
{
    if (self = [super initWithNibName:@"SettingsView" bundle:nil])
    {
        self.title = NSLocalizedString(@"Settings", @"Settings tab title");
        self.tabBarItem.image = [UIImage imageNamed:@"SettingsTab.png"];
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
        [self.tableView reloadData];
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

    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];

    // When there's no longer a SIM supplying country, reset the homeCountryFromSim settings.
    if ([NetworkStatus sharedStatus].simIsoCountryCode == nil &&
        [Settings sharedSettings].homeCountryFromSim == YES)
    {
        [Settings sharedSettings].homeCountryFromSim = NO;
        [self.tableView reloadData];
    }
}


#pragma mark - Table View Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return TableSectionNumber;
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString*   title = nil;

    switch (section)
    {
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
    }

    return title;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString*   title = nil;

    switch (section)
    {
        case TableSectionHomeCountry:
            title = NSLocalizedStringWithDefaultValue(@"Settings:HomeCountryInfo SectionFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"Determines how phone numbers without country code are interpreted.",
                                                      @"Explanation what the Home Country setting is doing\n"
                                                      @"[* lines]");
            break;

        case TableSectionCallOptions:
            title = NSLocalizedStringWithDefaultValue(@"Settings:CallOptionInfo SectionFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"Louder Volume extends the maximum volume; handy in noisy environments.",
                                                      @"Explanation what the Louder Volume setting is doing\n"
                                                      @"[* lines]");
    }

    return title;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger   numberOfRows = 0;

    switch (section)
    {
        case TableSectionHomeCountry:
            numberOfRows = ([NetworkStatus sharedStatus].simIsoCountryCode != nil) ? 2 : 1;
            break;

        case TableSectionCallOptions:
            numberOfRows = [NetworkStatus sharedStatus].simAvailable ? 2 : 1;
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

    switch (indexPath.section)
    {
        case TableSectionHomeCountry:
            [self.navigationController pushViewController:[[CountriesViewController alloc] init] animated:YES];
            break;

        default:
            break;
    }
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;

    switch (indexPath.section)
    {
        case TableSectionHomeCountry:
            cell = [self homeCountryCellForRowAtIndexPath:indexPath];
            break;

        case TableSectionCallOptions:
            cell = [self callOptionsCellForRowAtIndexPath:indexPath];
            break;
            
        default:
            break;
    }

    return cell;
}


- (UITableViewCell*)homeCountryCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;
    UISwitch*           switchView;

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
        switchView.on = [Settings sharedSettings].homeCountryFromSim;
        [switchView addTarget:self action:@selector(readFromSimSwitchAction:)
             forControlEvents:UIControlEventValueChanged];
    }

    if (([NetworkStatus sharedStatus].simIsoCountryCode != nil && indexPath.row == 1) ||
        [NetworkStatus sharedStatus].simIsoCountryCode == nil)
    {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
        }

        if ([Settings sharedSettings].homeCountry != nil)
        {
            // Note: This is also done in CountriesViewController (to update the
            //       selected cell before animation).  So pay a visit there when
            //       changing this.
            cell.imageView.image = [UIImage imageNamed:[Settings sharedSettings].homeCountry];
            cell.textLabel.text = [[CountryNames sharedNames] nameForIsoCountryCode:[Settings sharedSettings].homeCountry];
        }
        else
        {
            cell.imageView.image = nil;
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Settings:NoCountryName CellText", nil,
                                                                    [NSBundle mainBundle], @"No Country Selected",
                                                                    @"Table cell text, when user not selected home country yet\n"
                                                                    @"[1 line - abbreviated: 'Not Selected'");
        }
        
        if ([NetworkStatus sharedStatus].simIsoCountryCode != nil && [Settings sharedSettings].homeCountryFromSim)
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        else
        {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        }
    }

    return cell;
}


- (UITableViewCell*)callOptionsCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;
    UISwitch*           switchView;

    if ([NetworkStatus sharedStatus].simAvailable == YES && indexPath.row == 0)
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

        cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Settings:AllowDataCalls CellText", nil,
                                                                [NSBundle mainBundle], @"Cellular Data Calls",
                                                                @"Title of switch if calls over cellular data (3G/EDGE/...) are allowed\n"
                                                                @"[2/3 line - abbreviated: 'Data Calls'].");
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        switchView.on = [Settings sharedSettings].allowCellularDataCalls;
        [switchView addTarget:self action:@selector(allowDataCallsSwitchAction:)
             forControlEvents:UIControlEventValueChanged];
    }

    if (([NetworkStatus sharedStatus].simAvailable == YES && indexPath.row == 1) ||
        [NetworkStatus sharedStatus].simAvailable == NO)
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

        cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Settings:LouderVolume CellText", nil,
                                                                [NSBundle mainBundle], @"Louder Volume",
                                                                @"Title of switch if volume during call must be set a bit louder\n"
                                                                @"[2/3 line - abbreviated: 'Louder'].");
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        switchView.on = [Settings sharedSettings].louderVolume;
        [switchView addTarget:self action:@selector(louderVolumeSwitchAction:)
             forControlEvents:UIControlEventValueChanged];
    }

    return cell;
}


#pragma mark - UI Actions

- (void)readFromSimSwitchAction:(id)sender
{
    [Settings sharedSettings].homeCountryFromSim = ((UISwitch*)sender).on;
    if ([Settings sharedSettings].homeCountryFromSim)
    {
        [Settings sharedSettings].homeCountry = [NetworkStatus sharedStatus].simIsoCountryCode;
    }
    
    [self.tableView reloadData];
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
        [Settings sharedSettings].allowCellularDataCalls == NO)
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
                [Settings sharedSettings].allowCellularDataCalls = YES;
            }
            else
            {
                [allowDataCallsSwitch setOn:NO animated:YES];
            }
        }
                             cancelButtonTitle:[CommonStrings cancelString]
                             otherButtonTitles:[CommonStrings okString], nil];
    }
    else
    {
        [Settings sharedSettings].allowCellularDataCalls = NO;
    }
}


- (void)louderVolumeSwitchAction:(id)sender
{
    UISwitch*   louderVolumeSwitch = sender;

    [Settings sharedSettings].louderVolume = louderVolumeSwitch.on;
}

@end
