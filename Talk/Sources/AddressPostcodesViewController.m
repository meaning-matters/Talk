//
//  AddressPostcodesViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 08/04/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "AddressPostcodesViewController.h"
#import "BlockAlertView.h"
#import "Strings.h"
#import "Common.h"


@interface AddressPostcodesViewController ()

@property (nonatomic, strong) NSArray*         citiesArray;
@property (nonatomic, strong) AddressData*     address;
@property (nonatomic, strong) UITableViewCell* checkmarkedCell;        // Previous cell with checkmark.
@property (nonatomic, strong) NSDictionary*    selectedObject;

@end


@implementation AddressPostcodesViewController

- (instancetype)initWithCitiesArray:(NSArray*)citiesArray address:(AddressData*)address
{
    if (self = [super init])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"NumbersAreaZips ScreenTitle", nil, [NSBundle mainBundle],
                                                       @"Postcodes",
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

    [self sortOutArrays];
}


#pragma mark - Base Class Override

- (NSString*)nameForObject:(id)object
{
    return object[@"postcode"];
}


- (UIKeyboardType)searchBarKeyboardType
{
    return UIKeyboardTypeNumbersAndPunctuation;
}


- (id)selectedObject
{
    if (_selectedObject == nil)
    {
        if ([self.address.postcode length] == 0 && [self.address.city length] > 0)
        {
            // No postcode is selected, but we return the first one matching the city so
            // that the table is scrolled to the postcode(s) of the selected city.
            NSUInteger index = [self.objectsArray indexOfObjectPassingTest:^BOOL(NSDictionary* object,
                                                                                 NSUInteger    index,
                                                                                 BOOL*         stop)
            {
                return [object[@"city"] isEqualToString:self.address.city];
            }];

            _selectedObject = [self.objectsArray objectAtIndex:index];
        }
        else
        {
            // SearchTableViewController.m keep an internal objects array from the data passed with `createIndexOfWidth`.
            // In `sortOutArray` below, the `objectsArray` is created twice. After the first time, postcodes can be
            // padded with leading spaces (e.g. for South Korea with has 3 and 5 character postcodes). This is when
            // `createIndexOfWidth` is called, which then calls this function. That's why the objects here may have
            // padded postcodes which we trim before comparing with the `self.address.postcode` which never has leading
            // padding spaces.
            NSPredicate* predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary* bindings)
            {
                return [[evaluatedObject[@"postcode"] stringByTrimmingLeadingWhiteSpace] isEqualToString:self.address.postcode];
            }];

            _selectedObject = [[self.objectsArray filteredArrayUsingPredicate:predicate] firstObject];
        }
    }

    return _selectedObject;
}


#pragma mark - Helper Methods

- (void)sortOutArrays
{
    // Find maximum postcode size.
    NSUInteger maximumSize = 0;
    for (NSMutableDictionary* city in self.citiesArray)
    {
        for (NSString* postcode in city[@"postcodes"])
        {
            maximumSize = MAX(maximumSize, postcode.length);
        }
    }

    // Create one big postcodes array, and create city lookup dictionary/ The postcodes may
    // be padded with leading spaces to make the all the same width, which is needed for
    // proper index creation.
    //
    // This padding will be removed again below for display in the cells and when a cell is selected.
    NSMutableArray* objectsArray = [NSMutableArray array];
    for (NSMutableDictionary* city in self.citiesArray)
    {
        for (NSString* postcode in city[@"postcodes"])
        {
            NSString* padding = [[NSString string] stringByPaddingToLength:(maximumSize - postcode.length)
                                                                withString:@" "
                                                           startingAtIndex:0];

            [objectsArray addObject:@{@"postcode" : [padding stringByAppendingString:postcode],
                                      @"city"     : city[@"city"]}];
        }
    }

    // Determine a good width of section title, such that number of sections is
    // smaller than 40, and the number of sections is smaller than the total
    // number of items devided by a minimum section size of for example 5.
    //
    // This too must be done with postcodes of the same wdith. So we need the
    // padding (done above) too.
    NSInteger width;
    NSMutableDictionary* nameIndexDictionary = [NSMutableDictionary dictionary];
    for (width = maximumSize; width > 0; width--)
    {
        for (NSDictionary* object in objectsArray)
        {
            NSString* nameIndex = [object[@"postcode"] substringToIndex:width];
            if (([nameIndexDictionary valueForKey:nameIndex]) == nil)
            {
                nameIndexDictionary[nameIndex] = nameIndex;
            }
        }

        if (nameIndexDictionary.count <= 40 && nameIndexDictionary.count < objectsArray.count / 5)
        {
            [nameIndexDictionary removeAllObjects];
            break;
        }

        [nameIndexDictionary removeAllObjects];
    }

    // We create the index. This also requires the padded postcodes.
    self.objectsArray = objectsArray;
    [self createIndexOfWidth:width];
}


#pragma mark - Table View Delegates

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell   = [self.tableView cellForRowAtIndexPath:indexPath];
    NSDictionary*    object = [self objectOnTableView:tableView atIndexPath:indexPath];  // Potentially padded postcode.

    self.address.city     = object[@"city"];
    self.address.postcode = [object[@"postcode"] stringByTrimmingLeadingWhiteSpace];     // Strip padding.

    if (self.checkmarkedCell.accessoryType == UITableViewCellAccessoryCheckmark)
    {
        self.checkmarkedCell.accessoryType = UITableViewCellAccessoryNone;
    }

    cell.accessoryType = UITableViewCellAccessoryCheckmark;

    [self.navigationController popViewControllerAnimated:YES];
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    NSDictionary*    object = [self objectOnTableView:tableView atIndexPath:indexPath];  // Potentially padded postcode.

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"SubtitleCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"SubtitleCell"];
    }

    NSString* postcode        = [object[@"postcode"] stringByTrimmingLeadingWhiteSpace]; // Strip padding.
    cell.textLabel.text       = postcode;
    cell.detailTextLabel.text = object[@"city"];
    if ([postcode        isEqualToString:self.address.postcode] &&
        [object[@"city"] isEqualToString:self.address.city])
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
