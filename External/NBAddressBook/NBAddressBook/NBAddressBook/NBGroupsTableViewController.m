//
//  NBGroupsTableViewController.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/2/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import "NBGroupsTableViewController.h"

@implementation NBGroupsTableViewController

#pragma mark - Initialization
- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.navigationItem setTitle:NSLocalizedString(@"GRP_TITLE", @"")];
    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadGroupsPressed)]];
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed)]];
                                                
    // Load all available groups.
    [self loadGroups];
}


#pragma mark - Setting the datasource

- (void)setGroupsDatasource:(NSArray*)groupsArray
{
    groupsDatasource = [groupsArray sortedArrayUsingComparator:^NSComparisonResult(id a, id b)
    {
        NSString *first = [(NBGroup*)a groupName];
        NSString *second = [(NBGroup*)b groupName];
        return [first compare:second];
    }];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [groupsDatasource count] + 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"groupsCell";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    //Show/hide all groups
    if (indexPath.section == 0)
    {
        //Create the select/deselect button
        if ([self allGroupsSelected])
        {
            [cell.textLabel setText:NSLocalizedString(@"GRP_HIDE_ALL", @"")];
        }
        else
        {
            [cell.textLabel setText:NSLocalizedString(@"GRP_SHOW_ALL", @"")];
        }
    }
    //Load in each group
    else
    {
        //Load in the group's selection
        NBGroup * group = [groupsDatasource objectAtIndex:indexPath.section - 1];
        if (group.groupSelected)
        {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        //Set the title and alignment
        [cell.textLabel setText:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"GRP_KEYWORD_ALL", @""), group.groupName]];
        cell.textLabel.textAlignment = NSTextAlignmentLeft;
    }

    return cell;
}


#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Deselect the row
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    //Determine action to take
    if (indexPath.section == 0)
    {        
        //If all items were selected, deselect everything
        if ([self allGroupsSelected])
        {            
            [self selectAllGroups:NO];
            [self updateAllSelectionButtonText];
        }
        else
        {           
            [self selectAllGroups:YES];
            [self updateAllSelectionButtonText];
        }
    }
    else
    {
        //Select/deselect the grou
        UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
        NBGroup * group = [groupsDatasource objectAtIndex:indexPath.section - 1];
        [self setGroup:group selected:cell.accessoryType == UITableViewCellAccessoryNone];
        
        //Check the label for the total selection
        [self updateAllSelectionButtonText];
    }
}


- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    //Skip the all-button
    if (section > 0)
    {
        return [[groupsDatasource objectAtIndex:section-1] groupName];
    }
    else
    {
        return nil;
    }
}


- (void)updateAllSelectionButtonText
{
    //Set the title of the top quick-selection button
    NSIndexPath * indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if ([self allGroupsSelected])
    {
         [cell.textLabel setText:NSLocalizedString(@"GRP_HIDE_ALL", @"")];
    }
    else
    {
        [cell.textLabel setText:NSLocalizedString(@"GRP_SHOW_ALL", @"")];
    }
}


#pragma mark - Group selection

- (void)selectAllGroups:(BOOL)selectAll
{
    //Select/deselect all the groups
    for (NBGroup* group in groupsDatasource)
    {
        [self setGroup:group selected:selectAll];
    }
}


- (void)setGroup:(NBGroup*)group selected:(BOOL)select
{
    //Apply the selection in the view
    NSIndexPath*     indexPath = [NSIndexPath indexPathForRow:0 inSection:[groupsDatasource indexOfObject:group]+1];
    UITableViewCell* cell      = [self.tableView cellForRowAtIndexPath:indexPath];

    cell.accessoryType = select ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    //Apply the selection in the model
    [group setGroupSelected:select];
}


#pragma mark - Groups loading

- (void)loadGroups
{
#warning - Implement groups reloading the way you want
    
    //Reload the view
    [self.tableView reloadData];
}


#pragma mark - Button selectors
- (void)reloadGroupsPressed
{
    [self loadGroups];
}


- (void)donePressed
{
    //Save the selection and dismiss
    [[NSNotificationCenter defaultCenter] postNotificationName:NF_SAVE_GROUPS object:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Quick group selection check
- (BOOL)allGroupsSelected
{
    BOOL allGroupsSelected = YES;
    for (NBGroup * group in groupsDatasource)
    {
        if (![group groupSelected])
        {
            allGroupsSelected = NO;
            break;
        }
    }

    return allGroupsSelected;
}

@end
