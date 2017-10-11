//
//  AddressIdTypesViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 21/04/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import "AddressIdTypesViewController.h"


@interface AddressIdTypesViewController ()

@property (nonatomic, strong) NSIndexPath* selectedIndexPath;
@property (nonatomic, strong) IdType*      idType;
@property (nonatomic, strong) NSArray*     idTypes;
@property (nonatomic, copy) void (^completion)(void);

@end


@implementation AddressIdTypesViewController

- (instancetype)initWithIdType:(IdType*)idType idTypes:(NSArray*)idTypes completion:(void (^)(void))completion;
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        _idType     = idType;
        _idTypes    = idTypes;
        _completion = [completion copy];
    }

    return self;
}


#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.idTypes.count;
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    BOOL             selected;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }

    IdTypeValue value = [IdType valueForString:self.idTypes[indexPath.row]];
    selected = (self.idType.value == value);
    cell.textLabel.text = [IdType localizedStringForValue:value];

    self.selectedIndexPath = selected ? indexPath : self.selectedIndexPath;
    cell.accessoryType     = selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;

    return cell;
}


- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return 45;
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    self.idType.string = self.idTypes[indexPath.row];

    UITableViewCell* cell;

    cell               = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;

    cell               = [tableView cellForRowAtIndexPath:self.selectedIndexPath];
    cell.accessoryType = UITableViewCellAccessoryNone;

    self.completion ? self.completion() : 0;
    [self.navigationController popViewControllerAnimated:YES];
}

@end
