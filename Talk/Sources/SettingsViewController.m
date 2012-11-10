//
//  SettingsViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "SettingsViewController.h"
#import "Settings.h"
#import "NetworkStatus.h"


typedef enum
{
    TableSectionHomeCountry,
    TableSectionNumber          // Number of table sections.
} TableSections;


@interface SettingsViewController ()

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


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger   numberOfRows;

    switch (section)
    {
        case TableSectionHomeCountry:
            numberOfRows = [NetworkStatus sharedStatus].simAvailable ? 2 : 1;
            break;

        default:
            numberOfRows = 0;
            break;
    }

    return numberOfRows;
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;
    NSString*           cellIdentifier;

    switch (indexPath.section)
    {
        case TableSectionHomeCountry:
            if ([NetworkStatus sharedStatus].simAvailable)
            {
             //   if (indexPath.row == 0)
                {
                    cell = [tableView dequeueReusableCellWithIdentifier:@"SwitchCell"];
                    if (cell == nil)
                    {
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"SwitchCell"];
                    }

                    cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Settings:ReadFromSim CellText", nil,
                                                                            [NSBundle mainBundle], @"Read From SIM",
                                                                            @"Title of switch if home country must be read from SIM card.");
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    UISwitch*   switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
                    switchView.on = [Settings sharedSettings].homeCountryFromSim;
                    cell.accessoryView = switchView;
                    [switchView addTarget:self action:@selector(readFromSimSwitchAction:)
                         forControlEvents:UIControlEventValueChanged];
                }
            }
            else
            {

            }
            break;

        default:
            break;
    }

    return cell;
}


#pragma mark - UI Actions

- (void)readFromSimSwitchAction:(id)sender
{
    NSLog(@"%d", ((UISwitch*)sender).on);
    [Settings sharedSettings].homeCountryFromSim = ((UISwitch*)sender).on;
    [self.tableView reloadData];
}

@end
