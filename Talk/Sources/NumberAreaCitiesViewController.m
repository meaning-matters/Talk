//
//  NumberAreaCitiesViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 08/04/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "NumberAreaCitiesViewController.h"
#import "BlockAlertView.h"
#import "Strings.h"
#import "Common.h"


@interface NumberAreaCitiesViewController ()
{
    NSArray*             citiesArray;
    NSMutableDictionary* purchaseInfo;
    UITableViewCell*     checkmarkedCell;   // Previous cell with checkmark.
}

@end


@implementation NumberAreaCitiesViewController

- (instancetype)initWithCitiesArray:(NSArray*)array purchaseInfo:(NSMutableDictionary*)info;
{
    if (self = [super init])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"NumbersAreaCities ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"Cities",
                                                       @"Title of app screen with list of cities\n"
                                                       @"[1 line larger font].");

        citiesArray  = array;
        purchaseInfo = info;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem*    cancelButton;
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                 target:self
                                                                 action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = cancelButton;

    self.objectsArray = citiesArray;
    [self createIndexOfWidth:1];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.searchDisplayController setActive:NO animated:YES];
}


#pragma mark - Base Class Override

- (NSString*)nameForObject:(id)object
{
    NSMutableDictionary* city = object;

    return city[@"city"];
}


- (NSString*)selectedName
{
    return purchaseInfo[@"city"];
}


#pragma mark - Helper Methods

- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Table View Delegates

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
    NSString*        name = [self nameOnTable:tableView atIndexPath:indexPath];

    // If a ZIP code is already selected, check if it matches the city.
    NSString*   mismatchZipCode = purchaseInfo[@"zipCode"];
    if (purchaseInfo[@"zipCode"] != nil)
    {
        for (NSDictionary* city in citiesArray)
        {
            if ([name isEqualToString:city[@"city"]])
            {
                // Found selected city, now check if current ZIP code belongs.
                for (NSString* zipCode in city[@"zipCodes"])
                {
                    if ([purchaseInfo[@"zipCode"] isEqualToString:zipCode])
                    {
                        // Yes, the selected city matches the current ZIP code, so no problem.
                        mismatchZipCode = nil;
                        break;
                    }
                }
            }
        }
    }

    if (mismatchZipCode.length == 0)
    {
        if (checkmarkedCell.accessoryType == UITableViewCellAccessoryCheckmark)
        {
            checkmarkedCell.accessoryType = UITableViewCellAccessoryNone;
        }

        cell.accessoryType = UITableViewCellAccessoryCheckmark;

        purchaseInfo[@"city"] = name;

        [self.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        NSString*   title;
        NSString*   message;

        title = NSLocalizedStringWithDefaultValue(@"NumberAreaCities ZipMismatchAlertTitle", nil,
                                                  [NSBundle mainBundle], @"ZIP Code Mismatch",
                                                  @"Alert title saying that ZIP code does not match.\n"
                                                  @"[iOS alert title size - use correct term for 'ZIP code'].");
        message = NSLocalizedStringWithDefaultValue(@"NumberAreaCities ZipMismatchAlertMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"The current ZIP code: %@, does not match the city "
                                                    @"you selected.\nYou will have to select a ZIP code again.",
                                                    @"Alert message telling saying that ZIP code does not match.\n"
                                                    @"[iOS alert message size - use correct term for 'ZIP code']");
        message = [NSString stringWithFormat:message, mismatchZipCode];
        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
         {
             if (buttonIndex == 1)
             {
                 if (checkmarkedCell.accessoryType == UITableViewCellAccessoryCheckmark)
                 {
                     checkmarkedCell.accessoryType = UITableViewCellAccessoryNone;
                 }

                 cell.accessoryType = UITableViewCellAccessoryCheckmark;

                 [purchaseInfo removeObjectForKey:@"zipCode"];
                 purchaseInfo[@"city"] = name;

                 [self.navigationController popViewControllerAnimated:YES];
             }
             else
             {
                 [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
             }
         }
                             cancelButtonTitle:[Strings cancelString]
                             otherButtonTitles:[Strings okString], nil];
    }
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    NSString*        name = [self nameOnTable:tableView atIndexPath:indexPath];

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }

    cell.textLabel.text = name;
    if ([name isEqualToString:purchaseInfo[@"city"]])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        checkmarkedCell = cell;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}

@end
