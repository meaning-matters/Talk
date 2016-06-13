//
//  AddressMunicipalitiesViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 11/06/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import "AddressMunicipalitiesViewController.h"
#import "Strings.h"

@interface AddressMunicipalitiesViewController ()

@property (nonatomic, strong) AddressData*     address;
@property (nonatomic, strong) UITableViewCell* checkmarkedCell;        // Previous cell with checkmark.
@property (nonatomic, strong) NSDictionary*    selectedObject;

@end

@implementation AddressMunicipalitiesViewController

- (instancetype)initWithMunicipalitiesArray:(NSArray*)municipalitiesArray address:(AddressData*)address
{
    if (self = [super init])
    {
        self.title = [Strings municipalityCodeString];

        self.objectsArray = municipalitiesArray;
        self.address      = address;

        [self createIndexOfWidth:1];
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
}


#pragma mark - Base Class Override

- (NSString*)nameForObject:(id)object
{
    return object[@"code"];
}


- (UIKeyboardType)searchBarKeyboardType
{
    return UIKeyboardTypeNumbersAndPunctuation;
}


- (id)selectedObject
{
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"code = %@", self.address.municipalityCode];

    return [[self.objectsArray filteredArrayUsingPredicate:predicate] firstObject];
}


#pragma mark - Table View Delegates

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell   = [self.tableView cellForRowAtIndexPath:indexPath];
    NSDictionary*    object = [self objectOnTableView:tableView atIndexPath:indexPath];

    self.address.municipalityCode = object[@"code"];

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

    cell.textLabel.text       = object[@"code"];
    cell.detailTextLabel.text = object[@"name"];
    if ([object[@"code"] isEqualToString:self.address.municipalityCode])
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
