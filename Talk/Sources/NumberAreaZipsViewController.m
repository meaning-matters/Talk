//
//  NumberAreaZipsViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 08/04/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "NumberAreaZipsViewController.h"
#import "BlockAlertView.h"
#import "Strings.h"
#import "Common.h"


@interface NumberAreaZipsViewController ()
{
    NSArray*                citiesArray;
    NSMutableDictionary*    cityLookupDictionary;   // A map between ZIP code and matching city.

    NSMutableDictionary*    purchaseInfo;

    UITableViewCell*        checkmarkedCell;        // Previous cell with checkmark.
}

@end


@implementation NumberAreaZipsViewController

- (instancetype)initWithCitiesArray:(NSArray*)array purchaseInfo:(NSMutableDictionary*)info
{
    if (self = [super init])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"NumbersAreaZips ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"ZIP Codes",
                                                       @"Title of app screen with list of postal codes\n"
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

    [self sortOutArrays];
}


#pragma mark - Base Class Override

- (NSString*)nameForObject:(id)object
{
    return object;
}


- (UIKeyboardType)searchBarKeyboardType
{
    return UIKeyboardTypeNumbersAndPunctuation;
}


- (NSString*)selectedName
{
    return purchaseInfo[@"zipCode"];
}


#pragma mark - Helper Methods

- (void)sortOutArrays
{
    NSMutableArray* zipCodesArray = [NSMutableArray array];
    cityLookupDictionary          = [NSMutableDictionary dictionary];

    // Create one big ZIP codes array, and create city lookup dictionary.
    for (NSMutableDictionary* city in citiesArray)
    {
        [zipCodesArray addObjectsFromArray:city[@"zipCodes"]];

        for (NSString* zipCode in city[@"zipCodes"])
        {
            cityLookupDictionary[zipCode] = city[@"city"];
        }
    }

    // Find maximum ZIP code size.
    NSUInteger maximumSize = 0;
    for (NSString* zipCode in zipCodesArray)
    {
        if (zipCode.length > maximumSize)
        {
            maximumSize = zipCode.length;
        }
    }

    // Determine a good width of section title, such that number of sections is
    // smaller than 40, and the number of sections is smaller than the total
    // number of items devided by a minimum section size of for example 5.
    NSInteger width;
    NSMutableDictionary* nameIndexDictionary = [NSMutableDictionary dictionary];
    for (width = maximumSize; width > 0; width--)
    {
        for (NSString* zipCode in zipCodesArray)
        {
            NSString* nameIndex = [zipCode substringToIndex:width];
            if (([nameIndexDictionary valueForKey:nameIndex]) == nil)
            {
                nameIndexDictionary[nameIndex] = nameIndex;
            }
        }

        if (nameIndexDictionary.count <= 40 && nameIndexDictionary.count < zipCodesArray.count / 5)
        {
            [nameIndexDictionary removeAllObjects];
            break;
        }

        [nameIndexDictionary removeAllObjects];
    }

    self.objectsArray = zipCodesArray;
    [self createIndexOfWidth:width];
}


- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Table View Delegates

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
    NSString*        name = [self nameOnTable:tableView atIndexPath:indexPath];

    // Lookup city that belongs to this ZIP code, and check if it matches with current city.
    NSString* mismatchCity = nil;
    if ([purchaseInfo[@"city"] length] > 0 &&
        [[cityLookupDictionary objectForKey:name] isEqualToString:purchaseInfo[@"city"]] == NO)
    {
        mismatchCity = [cityLookupDictionary objectForKey:name];
    }
    else
    {
        // Set city that belongs to selected ZIP code.
        purchaseInfo[@"city"] = [cityLookupDictionary objectForKey:name];
    }

    if (mismatchCity == nil)
    {
        if (checkmarkedCell.accessoryType == UITableViewCellAccessoryCheckmark)
        {
            checkmarkedCell.accessoryType = UITableViewCellAccessoryNone;
        }

        cell.accessoryType = UITableViewCellAccessoryCheckmark;

        purchaseInfo[@"zipCode"] = name;

        [self.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        NSString*   title;
        NSString*   message;

        title = NSLocalizedStringWithDefaultValue(@"NumberAreaZips CityMismatchAlertTitle", nil,
                                                  [NSBundle mainBundle], @"City Mismatch",
                                                  @"Alert title saying that city does not match.\n"
                                                  @"[iOS alert title size].");
        message = NSLocalizedStringWithDefaultValue(@"NumberAreaZips CityMismatchAlertMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"The current city: %@, does not match the ZIP code you "
                                                    @"selected.\nDo you also want to select the correctly "
                                                    @"matching city: %@?",
                                                    @"Alert message telling saying that city does not match.\n"
                                                    @"[iOS alert message size - use correct term for "
                                                    @"'ZIP code']");
        message = [NSString stringWithFormat:message, [Common capitalizedString:purchaseInfo[@"city"]],
                                                      [Common capitalizedString:mismatchCity]];
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

                 purchaseInfo[@"zipCode"] = name;
                 purchaseInfo[@"city"]    = mismatchCity;

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

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"SubtitleCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"SubtitleCell"];
    }

    cell.textLabel.text = name;
    cell.detailTextLabel.text = [cityLookupDictionary objectForKey:name];
    if ([name isEqualToString:purchaseInfo[@"zipCode"]])
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
