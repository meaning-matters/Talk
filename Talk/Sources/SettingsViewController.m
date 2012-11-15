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


typedef enum
{
    TableSectionHomeCountry,
    TableSectionNumber          // Number of table sections.
} TableSections;


@interface SettingsViewController ()
{
    NSIndexPath*    selectedIndexPath;
}

@end


@implementation SettingsViewController

@synthesize tableView = _tableView;

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

    [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
    selectedIndexPath = nil;

    // When there's no longer a SIM supplying country, reset the homeCountryFromSim settings.
    if ([NetworkStatus sharedStatus].simIsoCountryCode == nil &&
        [Settings sharedSettings].homeCountryFromSim == YES)
    {
        [Settings sharedSettings].homeCountryFromSim = NO;
        [self.tableView reloadData];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - Table View Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return TableSectionNumber;
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString*   title;

    switch (section)
    {
        case TableSectionHomeCountry:
            title = NSLocalizedStringWithDefaultValue(@"Settings:HomeCountry SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Home Country",
                                                      @"Country where user lives (used to interpret dialed phone numbers).");
            break;

        default:
            title = nil;
            break;
    }

    return title;
}


- (NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return NSLocalizedStringWithDefaultValue(@"Settings:HomeCountryInfo SectionFooter", nil,
                                             [NSBundle mainBundle],
                                             @"The home country determines how phone numbers without country code are interpreted.",
                                             @"Explanation what the Home Country setting is doing\n"
                                             @"[* lines");
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger   numberOfRows;

    switch (section)
    {
        case TableSectionHomeCountry:
            numberOfRows = ([NetworkStatus sharedStatus].simIsoCountryCode != nil) ? 2 : 1;
            break;

        default:
            numberOfRows = 0;
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
            selectedIndexPath = indexPath;
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

@end
