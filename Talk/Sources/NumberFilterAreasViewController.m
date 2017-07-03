//
//  NumberFilterAreasViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 23/05/17.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import "NumberFilterAreasViewController.h"
#import "Common.h"
#import "Settings.h"
#import "Strings.h"


@interface NumberFilterAreasViewController ()

@property (nonatomic, strong) NSString*        isoCountryCode;
@property (nonatomic, copy)   void           (^completion)(NSDictionary* area);
@property (nonatomic, strong) UITableViewCell* selectedCell;

@end


@implementation NumberFilterAreasViewController

// The `areas` are always GEOGRAPHIC.
- (instancetype)initWithIsoCountryCode:(NSString*)isoCountryCode
                                 areas:(NSArray*)areas
                            completion:(void (^)(NSDictionary* area))completion
{
    if (self = [super init])
    {
        self.title = [Strings areaString];

        self.isoCountryCode = isoCountryCode;
        self.objectsArray   = areas;
        self.completion     = completion;

        [self createIndexOfWidth:1];
    }

    return self;
}


#pragma mark - Base Class Override

- (NSString*)nameForObject:(id)object
{
    NSString* name;

    name = [Common capitalizedString:object[@"areaName"]];

    // To allow searching for area code, add it behind the name. Before display it will be stripped away again below.
    name = [NSString stringWithFormat:@"%@ %@", name, object[@"areaCode"]];

    return name;
}


- (id)selectedObject
{
    NSString*     areaName  = [Settings sharedSettings].numberFilter[@"areaName"];
    NSPredicate*  predicate = [NSPredicate predicateWithFormat:@"areaName == %@", areaName];

    return [[self.objectsArray filteredArrayUsingPredicate:predicate] firstObject];
}


#pragma mark - Table View Delegates

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
    NSDictionary*    area = [self objectOnTableView:tableView atIndexPath:indexPath];

    self.selectedCell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryType = UITableViewCellAccessoryCheckmark;

    self.completion ? self.completion(area) : nil;

    [self.navigationController popViewControllerAnimated:YES];
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    NSDictionary*    area = [self objectOnTableView:tableView atIndexPath:indexPath];

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"DefaultCell"];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    NSString* code = area[@"areaCode"];
    NSString* name = [self nameForObject:area];

    if ([area[@"areaName"] isEqualToString:[Settings sharedSettings].numberFilter[@"areaName"]])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        self.selectedCell = cell;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    // Strip away area code that was only added to the names to allow searching for it.
    NSMutableArray* components = [[name componentsSeparatedByString:@" "] mutableCopy];
    [components removeObjectAtIndex:(components.count - 1)];
    name = [components componentsJoinedByString:@" "];

    cell.imageView.image      = [UIImage imageNamed:self.isoCountryCode];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"+%@ %@", [Common callingCodeForCountry:self.isoCountryCode], code];

    cell.textLabel.text = name;

    return cell;
}

@end
