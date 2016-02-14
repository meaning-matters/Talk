//
//  NumberAreaSalutationsViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 18/08/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "NumberAreaSalutationsViewController.h"
#import "Strings.h"


@interface NumberAreaSalutationsViewController ()

@property (nonatomic, strong) NSIndexPath* selectedIndexPath;
@property (nonatomic, strong) Salutation*  salutation;
@property (nonatomic, copy) void (^completion)(void);

@end


@implementation NumberAreaSalutationsViewController

- (instancetype)initWithSalutation:(Salutation*)salutation completion:(void (^)(void))completion
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"NumbersAreaTitles ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"Titles",
                                                       @"Title of screen with list of titles: Mr., Ms., ...\n"
                                                       @"[1 line larger font].");

        _salutation = salutation;
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
    return 3;
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
            selected = (self.salutation.value == SalutationValueMs);
            cell.textLabel.text = [Salutation localizedStringForValue:SalutationValueMs];
            break;
        }
        case 1:
        {
            selected = (self.salutation.value == SalutationValueMr);
            cell.textLabel.text = [Salutation localizedStringForValue:SalutationValueMr];
            break;
        }
        case 2:
        {
            selected = (self.salutation.value == SalutationValueCompany);
            cell.textLabel.text = [Salutation localizedStringForValue:SalutationValueCompany];
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
            self.salutation.value = SalutationValueMs;
            break;
        }
        case 1:
        {
            self.salutation.value = SalutationValueMr;
            break;
        }
        case 2:
        {
            self.salutation.value = SalutationValueCompany;
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
