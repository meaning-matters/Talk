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

@property (nonatomic, strong) NSArray*         citiesArray;
@property (nonatomic, strong) AddressData*     address;
@property (nonatomic, strong) UITableViewCell* checkmarkedCell;   // Previous cell with checkmark.

@end


@implementation NumberAreaCitiesViewController

- (instancetype)initWithCitiesArray:(NSArray*)citiesArray address:(AddressData *)address
{
    if (self = [super init])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"NumbersAreaCities ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"Cities",
                                                       @"Title of app screen with list of cities\n"
                                                       @"[1 line larger font].");

        self.citiesArray = citiesArray;
        self.address     = address;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.objectsArray = self.citiesArray;
    [self createIndexOfWidth:1];
}


#pragma mark - Base Class Override

- (NSString*)nameForObject:(id)object
{
    NSMutableDictionary* city = object;

    return city[@"city"];
}


- (id)selectedObject
{
    NSPredicate* predicate     = [NSPredicate predicateWithFormat:@"(city == %@)", self.address.city];
    NSArray*     filteredArray = [self.citiesArray filteredArrayUsingPredicate:predicate];

    return [filteredArray firstObject];
}


#pragma mark - Table View Delegates

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell   = [self.tableView cellForRowAtIndexPath:indexPath];
    NSDictionary*    object = [self objectOnTableView:tableView atIndexPath:indexPath];

    if (self.checkmarkedCell.accessoryType == UITableViewCellAccessoryCheckmark)
    {
        self.checkmarkedCell.accessoryType = UITableViewCellAccessoryNone;
    }

    cell.accessoryType = UITableViewCellAccessoryCheckmark;

    self.address.city = object[@"city"];
    if ([object[@"postcodes"] containsObject:self.address.postcode] == NO)
    {
        if ([object[@"postcodes"] count] == 1)
        {
            self.address.postcode = [object[@"postcodes"] firstObject];
        }
        else
        {
            self.address.postcode = nil;
        }
    }

    [self.navigationController popViewControllerAnimated:YES];
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    NSString*        name = [self nameOnTableView:tableView atIndexPath:indexPath];

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }

    cell.textLabel.text = name;
    if ([name isEqualToString:self.address.city])
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
