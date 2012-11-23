//
//  CountriesViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 12/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "CountriesViewController.h"
#import "SettingsViewController.h"
#import "CountryNames.h"
#import "Settings.h"

@interface CountriesViewController ()
{
    NSArray*                namesArray;
    NSMutableDictionary*    nameIndexDictionary;
    NSArray*                nameIndexArray;
    UITableViewCell*        selectedCell;
}

@end


@implementation CountriesViewController

@synthesize tableView = _tableView;
@synthesize isModal   = _isModal;


- (id)init
{
    if (self = [super initWithNibName:@"CountriesView" bundle:nil])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"Countries:CountriesList ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"Countries",
                                                       @"Title of app screen with list of countries\n"
                                                       @"[1 line larger font].");

        namesArray = [[CountryNames sharedNames].namesDictionary allValues];
        nameIndexDictionary = [NSMutableDictionary dictionary];
        for (NSString* name in namesArray)
        {
            NSString*       nameIndex = [name substringToIndex:1];
            NSMutableArray* indexArray;
            if ((indexArray = [nameIndexDictionary valueForKey:nameIndex]) != nil)
            {
                [indexArray addObject:name];
            }
            else
            {
                indexArray = [NSMutableArray array];
                [nameIndexDictionary setObject:indexArray forKey:nameIndex];
                [indexArray addObject:name];
            }
        }

        nameIndexArray = [[nameIndexDictionary allKeys] sortedArrayUsingSelector:@selector(localizedCompare:)];
        for (NSString* nameIndex in nameIndexArray)
        {
            [[nameIndexDictionary objectForKey:nameIndex] sortedArrayUsingSelector:@selector(localizedCompare:)];
        }
    }

    return self;
}


- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    if (self.isModal)
    {
        UIBarButtonItem*           cancelButton;

        cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                     target:self
                                                                     action:@selector(cancel)];

        self.navigationItem.leftBarButtonItem = cancelButton;
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - Table View Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return [nameIndexArray count];
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    return nameIndexArray[section];
}


- (NSArray*)sectionIndexTitlesForTableView:(UITableView*)tableView
{
    return nameIndexArray;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[nameIndexDictionary objectForKey:nameIndexArray[section]] count];
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSString*           name = [nameIndexDictionary objectForKey:nameIndexArray[indexPath.section]][indexPath.row];
    UITableViewCell*    cell = [self.tableView cellForRowAtIndexPath:indexPath];

    [Settings sharedSettings].homeCountry = [[CountryNames sharedNames] isoCountryCodeForName:name];

    selectedCell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    selectedCell = cell;

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (self.isModal == YES)
    {
        // Shown as modal.
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
        // Shown from Settings.
        // Set the parent cell to prevent quick update right after animations.
        NSArray*                viewControllers = self.navigationController.viewControllers;
        SettingsViewController* parent = (SettingsViewController*)[viewControllers objectAtIndex:[viewControllers count] - 2];
        NSIndexPath*            parentIndexPath = parent.tableView.indexPathForSelectedRow;
        UITableViewCell*        parentCell = [parent.tableView cellForRowAtIndexPath:parentIndexPath];
        parentCell.imageView.image = [UIImage imageNamed:[Settings sharedSettings].homeCountry];
        parentCell.textLabel.text = [[CountryNames sharedNames] nameForIsoCountryCode:[Settings sharedSettings].homeCountry];

        [self.navigationController popViewControllerAnimated:YES];
    }
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }

    NSString*   name = [nameIndexDictionary objectForKey:nameIndexArray[indexPath.section]][indexPath.row];
    NSString*   isoCountryCode = [[CountryNames sharedNames] isoCountryCodeForName:name];

    cell.imageView.image = [UIImage imageNamed:isoCountryCode];
    cell.textLabel.text = name;

    if ([isoCountryCode isEqualToString:[Settings sharedSettings].homeCountry])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        selectedCell = cell;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}

@end
