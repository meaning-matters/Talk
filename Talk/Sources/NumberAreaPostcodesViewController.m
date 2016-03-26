//
//  NumberAreaPostcodesViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 08/04/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "NumberAreaPostcodesViewController.h"
#import "BlockAlertView.h"
#import "Strings.h"
#import "Common.h"


@interface NumberAreaPostcodesViewController ()

@property (nonatomic, strong) NSArray*             citiesArray;
@property (nonatomic, strong) NSMutableDictionary* cityLookupDictionary;   // A map between postcode and matching city.

@property (nonatomic, strong) AddressData*         address;

@property (nonatomic, strong) UITableViewCell*     checkmarkedCell;        // Previous cell with checkmark.

@end


@implementation NumberAreaPostcodesViewController

- (instancetype)initWithCitiesArray:(NSArray*)citiesArray address:(AddressData*)address
{
    if (self = [super init])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"NumbersAreaZips ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"Postcodes",
                                                       @"Title of app screen with list of postal codes\n"
                                                       @"[1 line larger font].");
        
        self.citiesArray = citiesArray;
        self.address     = address;
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem* cancelButton;
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
    if ([self.address.postcode length] == 0 && [self.address.city length] > 0)
    {
        // No postcode is selected, but we return the first one matching the city so
        // that the table is scrolled to the postcode(s) of the selected city.
        NSUInteger index = [self.objectsArray indexOfObjectPassingTest:^BOOL(NSString*  postcode,
                                                                             NSUInteger index,
                                                                             BOOL*      stop)
        {
            return [self.cityLookupDictionary[postcode] isEqualToString:self.address.city];
        }];

        if (index == NSNotFound)
        {
            //### Same postcode for multiple cities.
            index = 0;
        }

        return [self.objectsArray objectAtIndex:index];
    }
    else
    {
        return self.address.postcode;
    }
}


#pragma mark - Helper Methods

- (void)sortOutArrays
{
    NSMutableArray* postcodesArray = [NSMutableArray array];
    self.cityLookupDictionary      = [NSMutableDictionary dictionary];

    // Create one big postcodes array, and create city lookup dictionary.
    for (NSMutableDictionary* city in self.citiesArray)
    {
        [postcodesArray addObjectsFromArray:city[@"postcodes"]];

        for (NSString* postcode in city[@"postcodes"])
        {
            self.cityLookupDictionary[postcode] = city[@"city"];
        }
    }

    // Find maximum postcode size.
    NSUInteger maximumSize = 0;
    for (NSString* postcode in postcodesArray)
    {
        if (postcode.length > maximumSize)
        {
            maximumSize = postcode.length;
        }
    }

    // Determine a good width of section title, such that number of sections is
    // smaller than 40, and the number of sections is smaller than the total
    // number of items devided by a minimum section size of for example 5.
    NSInteger width;
    NSMutableDictionary* nameIndexDictionary = [NSMutableDictionary dictionary];
    for (width = maximumSize; width > 0; width--)
    {
        for (NSString* postcode in postcodesArray)
        {
            NSString* nameIndex = [postcode substringToIndex:width];
            if (([nameIndexDictionary valueForKey:nameIndex]) == nil)
            {
                nameIndexDictionary[nameIndex] = nameIndex;
            }
        }

        if (nameIndexDictionary.count <= 40 && nameIndexDictionary.count < postcodesArray.count / 5)
        {
            [nameIndexDictionary removeAllObjects];
            break;
        }

        [nameIndexDictionary removeAllObjects];
    }

    self.objectsArray = postcodesArray;
    [self createIndexOfWidth:width];
}


- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Table View Delegates

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell     = [self.tableView cellForRowAtIndexPath:indexPath];
    NSString*        postcode = [self nameOnTable:tableView atIndexPath:indexPath];

    // Lookup city that belongs to this postcode, and check if it matches with current city.
    NSString* mismatchCity = nil;
    if ([self.address.city length] > 0 &&
        [self.cityLookupDictionary[postcode] isEqualToString:self.address.city] == NO)
    {
        mismatchCity = self.cityLookupDictionary[postcode];
    }
    else
    {
        // Set city that belongs to selected postcode.
        self.address.city = self.cityLookupDictionary[postcode];
    }

    if (mismatchCity == nil)
    {
        if (self.checkmarkedCell.accessoryType == UITableViewCellAccessoryCheckmark)
        {
            self.checkmarkedCell.accessoryType = UITableViewCellAccessoryNone;
        }

        cell.accessoryType = UITableViewCellAccessoryCheckmark;

        self.address.postcode = postcode;

        [self.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        NSString* title;
        NSString* message;

        title = NSLocalizedStringWithDefaultValue(@"NumberAreaZips CityMismatchAlertTitle", nil,
                                                  [NSBundle mainBundle], @"City Mismatch",
                                                  @"Alert title saying that city does not match.\n"
                                                  @"[iOS alert title size].");
        message = NSLocalizedStringWithDefaultValue(@"NumberAreaZips CityMismatchAlertMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"The current city: %@, does not match the postcode you "
                                                    @"selected.\nDo you also want to select the correctly "
                                                    @"matching city: %@?",
                                                    @"Alert message telling saying that city does not match.\n"
                                                    @"[iOS alert message size]");
        message = [NSString stringWithFormat:message, [Common capitalizedString:self.address.city],
                                                      [Common capitalizedString:mismatchCity]];
        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
         {
             if (buttonIndex == 1)
             {
                 if (self.checkmarkedCell.accessoryType == UITableViewCellAccessoryCheckmark)
                 {
                     self.checkmarkedCell.accessoryType = UITableViewCellAccessoryNone;
                 }

                 cell.accessoryType = UITableViewCellAccessoryCheckmark;

                 self.address.postcode = postcode;
                 self.address.city     = mismatchCity;

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
    NSString*        postcode = [self nameOnTable:tableView atIndexPath:indexPath];

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"SubtitleCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"SubtitleCell"];
    }

    cell.textLabel.text = postcode;
    cell.detailTextLabel.text = self.cityLookupDictionary[postcode];
    if ([postcode isEqualToString:self.address.postcode])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        self.checkmarkedCell = cell;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}

@end
