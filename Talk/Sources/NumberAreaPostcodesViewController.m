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

@property (nonatomic, strong) NSArray*         citiesArray;
@property (nonatomic, strong) AddressData*     address;
@property (nonatomic, strong) UITableViewCell* checkmarkedCell;        // Previous cell with checkmark.

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

        return [self.objectsArray objectAtIndex:index];
    }
    else
    {
        NSPredicate* predicate     = [NSPredicate predicateWithFormat:@"(postcode == %@)", self.address.postcode];
        NSArray*     filteredArray = [self.objectsArray filteredArrayUsingPredicate:predicate];

        return [filteredArray firstObject];
    }
}


#pragma mark - Helper Methods

- (void)sortOutArrays
{
    NSMutableArray* objectsArray = [NSMutableArray array];

    // Create one big postcodes array, and create city lookup dictionary.
    for (NSMutableDictionary* city in self.citiesArray)
    {
        for (NSString* postcode in city[@"postcodes"])
        {
            [objectsArray addObject:@{@"postcode" : postcode,
                                      @"city"     : city[@"city"]}];
        }
    }

    // Find maximum postcode size.
    NSUInteger maximumSize = 0;
    for (NSDictionary* object in objectsArray)
    {
        if ([object[@"postcode"] length] > maximumSize)
        {
            maximumSize = [object[@"postcode"] length];
        }
    }

    // Determine a good width of section title, such that number of sections is
    // smaller than 40, and the number of sections is smaller than the total
    // number of items devided by a minimum section size of for example 5.
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

    self.objectsArray = objectsArray;
    [self createIndexOfWidth:width];
}


#pragma mark - Table View Delegates

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell   = [self.tableView cellForRowAtIndexPath:indexPath];
    NSDictionary*    object = [self objectOnTableView:tableView atIndexPath:indexPath];

    self.address.city     = object[@"city"];
    self.address.postcode = object[@"postcode"];

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
    NSDictionary*    object = [self objectOnTableView:tableView atIndexPath:indexPath];

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"SubtitleCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"SubtitleCell"];
    }

    cell.textLabel.text       = object[@"postcode"];
    cell.detailTextLabel.text = object[@"city"];
    if ([object[@"postcode"] isEqualToString:self.address.postcode])
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
