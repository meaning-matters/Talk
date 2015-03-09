//
//  NBNewFieldTableViewController.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/5/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import "NBNewFieldTableViewController.h"

@implementation NBNewFieldTableViewController

@synthesize structureManager;

#pragma mark - initialization
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Set the navigation cancel button
    UIBarButtonItem * cancelButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPressed)];
    [self.navigationItem setLeftBarButtonItem:cancelButton];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections
    return 7;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //Determine the rows based on visibility
    switch (section) {
        case NF_NAME: //The name-section
        {
            //Total amount of name-cells minutes the visible ones
            return [[structureManager getVisibleRows:NO ForSection:CC_NAME] count];
        }
            break;
        case NF_SOCIAL: //Twitter, Facebook
        {
            //Only show if this section hasn't been added yet
            int numRowsInSection = [[structureManager.tableStructure objectAtIndex:CC_SOCIAL] count];
            return numRowsInSection > 0 ? 0 : 1;
        }
            break;
        case NF_IM: //Instant Message
        {
            //Only show if this section hasn't been added yet      
            int numRowsInSection = [[structureManager.tableStructure objectAtIndex:CC_IM] count];
            return numRowsInSection > 0 ? 0 : 1;
        }
            break;
        case NF_BIRTHDAY: //Birthday
        {
            //Only show if this section hasn't been added yet
            int numRowsInSection = [[structureManager.tableStructure objectAtIndex:CC_BIRTHDAY] count];
            return numRowsInSection > 0 ? 0 : 1;
        }
            break;
        case NF_DATES: //Dates
        {
            //Only show if this section hasn't been added yet
            int numRowsInSection = [[structureManager.tableStructure objectAtIndex:CC_OTHER_DATES] count];
            return numRowsInSection > 0 ? 0 : 1;
        }
            break;
        case NF_RELATED: //Related contacts
        {
            //Only show if this section hasn't been added yet
            int numRowsInSection = [[structureManager.tableStructure objectAtIndex:CC_RELATED_CONTACTS] count];
            return numRowsInSection > 0 ? 0 : 1;
        }
            break;
        case NF_NOTES: //Notes
        {
            //Only show if this section hasn't been added yet
            int numRowsInSection = [[structureManager.tableStructure objectAtIndex:CC_NOTES] count];
            return numRowsInSection > 0 ? 0 : 1;
        }
            break;            
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    
    switch (indexPath.section) {
        case NF_NAME:
        {
            NSMutableArray * invisibleRows = [structureManager getVisibleRows:NO ForSection:CC_NAME];
            cell.textLabel.text = ((NBPersonCellInfo*)[invisibleRows objectAtIndex:indexPath.row]).textfieldPlaceHolder;
        }
            break;
        case NF_SOCIAL:
        {
            cell.textLabel.text = (__bridge NSString *)(ABPersonCopyLocalizedPropertyName(kABPersonSocialProfileProperty));
        }
            break;
        case NF_IM:
        {
            cell.textLabel.text = (__bridge NSString *)(ABPersonCopyLocalizedPropertyName(kABPersonInstantMessageProperty));
        }
            break;
        case NF_BIRTHDAY:
        {
            cell.textLabel.text = (__bridge NSString *)(ABPersonCopyLocalizedPropertyName(kABPersonBirthdayProperty));
        }
            break;            
        case NF_DATES:
        {
            cell.textLabel.text = (__bridge NSString *)(ABPersonCopyLocalizedPropertyName(kABPersonDateProperty));
        }
            break;
        case NF_RELATED:
        {
            cell.textLabel.text = (__bridge NSString *)(ABPersonCopyLocalizedPropertyName(kABPersonRelatedNamesProperty));
        }
            break;
        case NF_NOTES:
        {
            cell.textLabel.text = (__bridge NSString *)(ABPersonCopyLocalizedPropertyName(kABPersonNoteProperty));
        }
            break;
        default:
            break;
    }
    
    //Set the cell color
    [cell.textLabel setFont:[UIFont boldSystemFontOfSize:14]];
    [cell.textLabel setTextColor:FONT_COLOR_LABEL];
    
    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Cells are added by creating their CellInfo
    NSIndexPath * indexPathToFocusOn;
    switch (indexPath.section) {
        case NF_NAME:
        {
            //Mark this cell as visible
            NSMutableArray * invisibleRows = [structureManager getVisibleRows:NO ForSection:CC_NAME];
            NBPersonCellInfo * cellInfo = [invisibleRows objectAtIndex:indexPath.row];
            [cellInfo setMakeFirstResponder:YES];
            [cellInfo setVisible:YES];
            
            //Look up the visible rowposition to scroll to
            int rowPosition = 0;
            NSMutableArray * visibleRows = [structureManager getVisibleRows:YES ForSection:CC_NAME];
            for (NBPersonCellInfo * curCellinfo in visibleRows)
            {
                if (curCellinfo == cellInfo)
                {
                    break;
                }
                else
                {
                    rowPosition++;
                }
            }

            //Focus on this field after dismissing
            indexPathToFocusOn = [NSIndexPath indexPathForRow:rowPosition inSection:CC_NAME];
        }
            break;
        case NF_SOCIAL:
        {
            //Create the first social cellInfo
            NSMutableArray * sectionArray = [structureManager.tableStructure objectAtIndex:CC_SOCIAL];
            NBPersonCellInfo * cellInfo = [[NBPersonCellInfo alloc]initWithPlaceholder:(__bridge NSString *)(ABAddressBookCopyLocalizedLabel(kABPersonInstantMessageUsernameKey)) andLabel:[SOCIAL_ARRAY objectAtIndex:0]];
            [cellInfo setMakeFirstResponder:YES];
            [sectionArray addObject:cellInfo];
            
            //Focus on this field after dismissing
            indexPathToFocusOn = [NSIndexPath indexPathForRow:0 inSection:CC_SOCIAL];
        }
            break;
        case NF_IM:
        {
            //Create the first IM cellInfo            
            NSMutableArray * sectionArray = [structureManager.tableStructure objectAtIndex:CC_IM];
            NBPersonCellInfo * cellInfo = [[NBPersonCellInfo alloc]initWithPlaceholder:(__bridge NSString *)(ABAddressBookCopyLocalizedLabel(kABPersonInstantMessageUsernameKey)) andLabel:(__bridge NSString *)(ABAddressBookCopyLocalizedLabel(kABHomeLabel))];
            [cellInfo setIMType:[IM_ARRAY objectAtIndex:0]];
            [cellInfo setMakeFirstResponder:YES];
            [sectionArray addObject:cellInfo];
            
            //Focus on this field after dismissing
            indexPathToFocusOn = [NSIndexPath indexPathForRow:[sectionArray count]-1 inSection:CC_IM];
        }
            break;
        case NF_BIRTHDAY:
        {
            //Create the first date cellInfo
            NSMutableArray * sectionArray = [structureManager.tableStructure objectAtIndex:CC_BIRTHDAY];
            NBPersonCellInfo * cellInfo = [[NBPersonCellInfo alloc]initWithPlaceholder:nil andLabel:(__bridge NSString *)(ABPersonCopyLocalizedPropertyName(kABPersonBirthdayProperty))];
            [cellInfo setMakeFirstResponder:YES];
            [sectionArray addObject:cellInfo];
            
            //Focus on this field after dismissing
            indexPathToFocusOn = [NSIndexPath indexPathForRow:0 inSection:CC_BIRTHDAY];
        }
            break;
        case NF_DATES:
        {
            //Create the first date cellInfo
            NSMutableArray * sectionArray = [structureManager.tableStructure objectAtIndex:CC_OTHER_DATES];
            NBPersonCellInfo * cellInfo = [[NBPersonCellInfo alloc]initWithPlaceholder:nil andLabel:(__bridge NSString *)(ABAddressBookCopyLocalizedLabel(kABPersonAnniversaryLabel))];
            [cellInfo setMakeFirstResponder:YES];            
            [sectionArray addObject:cellInfo];
            
            //Also add the other-cell
            [sectionArray addObject:[[NBPersonCellInfo alloc]initWithPlaceholder:(__bridge NSString *)(ABPersonCopyLocalizedPropertyName(kABPersonDateProperty)) andLabel:(__bridge NSString *)(ABAddressBookCopyLocalizedLabel(kABOtherLabel))]];
            
            //Focus on this field after dismissing
            indexPathToFocusOn = [NSIndexPath indexPathForRow:0 inSection:CC_OTHER_DATES];
        }
            break;
        case NF_RELATED:
        {
            //Create the related cellInfo            
            NSMutableArray * sectionArray = [structureManager.tableStructure objectAtIndex:CC_RELATED_CONTACTS];
            NBPersonCellInfo * cellInfo = [[NBPersonCellInfo alloc]initWithPlaceholder:NSLocalizedString(@"PH_NAME", @"") andLabel:            (__bridge NSString*)ABAddressBookCopyLocalizedLabel((__bridge CFStringRef)[RELATED_ARRAY objectAtIndex:0])];
            [cellInfo setMakeFirstResponder:YES];
            [sectionArray addObject:cellInfo];
            
            //Focus on this field after dismissing
            indexPathToFocusOn = [NSIndexPath indexPathForRow:0 inSection:CC_RELATED_CONTACTS];
        }
            break;
        case NF_NOTES:
        {
            //Create the notes cellInfo
            NSMutableArray * sectionArray = [structureManager.tableStructure objectAtIndex:CC_NOTES];
            NBPersonCellInfo * cellInfo = [[NBPersonCellInfo alloc]initWithPlaceholder:nil andLabel:(__bridge NSString *)(ABPersonCopyLocalizedPropertyName(kABPersonNoteProperty))];
            [cellInfo setMakeFirstResponder:YES];
            [sectionArray addObject:cellInfo];
            
            //Focus on this field after dismissing
            indexPathToFocusOn = [NSIndexPath indexPathForRow:0 inSection:CC_NOTES];
        }
            break;
            
        default:
            break;
    }

    [self.personViewDelegate scrollToRow:indexPathToFocusOn];
    [self setPersonViewDelegate:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

//Clear tableview header and footer-height to make sure hidden sections don't take up space
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    //In case of no rows, no footer
    if ([self tableView:self.tableView numberOfRowsInSection:section] == 0)
    {
        return 0.1f;
    }
    else
    {
        return UITableViewAutomaticDimension;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    //In case of no rows, no footer
    if ([self tableView:self.tableView numberOfRowsInSection:section] == 0)
    {
        return 0.1f;
    }
    else
    {
        return UITableViewAutomaticDimension;
    }
}

#pragma mark - Cancel new field
- (void)cancelPressed
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
