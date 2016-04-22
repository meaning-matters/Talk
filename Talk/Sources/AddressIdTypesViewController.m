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
@property (nonatomic, copy) void (^completion)(void);

@end


@implementation AddressIdTypesViewController

- (instancetype)initWithIdType:(IdType*)idType completion:(void (^)(void))completion;
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        _idType     = idType;
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
    return 4;
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

    switch (indexPath.row)
    {
        case 0:
        {
            selected = (self.idType.value == IdTypeValueDni);
            cell.textLabel.text = [IdType localizedStringForValue:IdTypeValueDni];
            break;
        }
        case 1:
        {
            selected = (self.idType.value == IdTypeValueNif);
            cell.textLabel.text = [IdType localizedStringForValue:IdTypeValueNif];
            break;
        }
        case 2:
        {
            selected = (self.idType.value == IdTypeValueNie);
            cell.textLabel.text = [IdType localizedStringForValue:IdTypeValueNie];
            break;
        }
        case 3:
        {
            selected = (self.idType.value == IdTypeValuePassport);
            cell.textLabel.text = [IdType localizedStringForValue:IdTypeValuePassport];
            break;
        }
    }

    self.selectedIndexPath = selected ? indexPath : self.selectedIndexPath;
    cell.accessoryType     = selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;

    return cell;
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    switch (indexPath.row)
    {
        case 0:
        {
            self.idType.value = IdTypeValueDni;
            break;
        }
        case 1:
        {
            self.idType.value = IdTypeValueNif;
            break;
        }
        case 2:
        {
            self.idType.value = IdTypeValueNie;
            break;
        }
        case 3:
        {
            self.idType.value = IdTypeValuePassport;
            break;
        }
    }

    UITableViewCell* cell;

    cell               = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;

    cell               = [tableView cellForRowAtIndexPath:self.selectedIndexPath];
    cell.accessoryType = UITableViewCellAccessoryNone;

    self.completion ? self.completion() : 0;
    [self.navigationController popViewControllerAnimated:YES];
}

@end
