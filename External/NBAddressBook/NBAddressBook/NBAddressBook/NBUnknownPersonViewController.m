//
//  NBUnknownPersonViewController.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/12/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import <AddressBookUI/AddressBookUI.h>
#import "NBUnknownPersonViewController.h"
#import "NBRecentUnknownContactViewController.h"

@implementation NBUnknownPersonViewController

@synthesize allowsAddingToAddressBook;
@synthesize allowsSendingMessage;
@synthesize message;
@synthesize unknownPersonViewDelegate;


#pragma mark - Initialization
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Load in a name
    personRepresentation = [NBContact getListRepresentation:self.contact.contactRef];
    
    //Load in the email
    emailAddress = [NBContact getAvailableProperty:kABPersonEmailProperty from:self.contact.contactRef];
    
    //Load in the number
    number = [NBContact getAvailableProperty:kABPersonPhoneProperty from:self.contact.contactRef];
#ifndef NB_STANDALONE
    number = [[NBAddressBookManager sharedManager].delegate formatNumber:number];
#endif

    //Reset the name based on loaded-in properties
    [self setNameLabel];
    
    //Hide the right bar button
    [self.navigationItem setRightBarButtonItem:nil];
}

#pragma mark - Set name label
- (void)setNameLabel
{
    if ([emailAddress length] > 0 || [number length] > 0)
    {
        //Measure variables
        UIFont *boldFont = [UIFont boldSystemFontOfSize:18];  //Font for bold name part
        UIFont *regularFont = [UIFont systemFontOfSize:14];   //Font for regular name part
        int totalLabelHeight = 0;
        
        //Build up the final string to set
        NSDictionary * boldAttributes       = [NSDictionary dictionaryWithObjectsAndKeys:
                                               boldFont, NSFontAttributeName,
                                               [UIColor blackColor], NSForegroundColorAttributeName, nil];
        NSDictionary * regularAttributes    = [NSDictionary dictionaryWithObjectsAndKeys:
                                               regularFont, NSFontAttributeName,
                                               [UIColor colorWithRed:76/255.0f green:86/255.0f blue:108/255.0f alpha:1.0f], NSForegroundColorAttributeName,nil];
        
        //If we don't have a representation yet, use the number
        if ([personRepresentation length] == 0)
        {
            personRepresentation = [[NSMutableAttributedString alloc] initWithString:emailAddress attributes:boldAttributes];
        }
        
        //Make the entire string bold
        [personRepresentation setAttributes:boldAttributes range:NSMakeRange(0, [personRepresentation length])];
        
        //If we have have a message, add it below the personRepresentation
        if ([message length] > 0)
        {
            NSMutableAttributedString * messageString = [[NSMutableAttributedString alloc]initWithString:message];
            [messageString setAttributes:regularAttributes range:NSMakeRange(0, [message length])];
            [personRepresentation appendAttributedString:[[NSAttributedString alloc]initWithString:@"\n"]];
            [personRepresentation appendAttributedString:messageString];
        }

        //Set the text in the label
        [nameLabel setAttributedText:personRepresentation];
        
        //Set the new frame
        [nameLabel setBackgroundColor:[UIColor clearColor]];
        CGRect nameRect = nameLabel.frame;
        totalLabelHeight = totalLabelHeight < SIZE_NAME_LABEL_MIN ? SIZE_NAME_LABEL_MIN : totalLabelHeight;
        nameLabel.frame = CGRectMake( nameRect.origin.x, nameRect.origin.y, nameRect.size.width, totalLabelHeight);
        
        //Set the cell height as well, so we have space to draw the label
        tableHeaderSize = totalLabelHeight + 20;
    }
}

#pragma mark - Reloading contact
- (void)reloadContact
{
    //Leave empty, nothing needs to happen
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    //Four sections (plus the first one to bump down the cells for the name)
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case UP_FILLER:
        {
            return 1;
        }
        case UP_EMAIL:
        {
            return [emailAddress length] > 0 ? 1 : 0;
        }
        case UP_CONTACT:
        {
            return ([number length] > 0) ? (allowsSendingMessage ? 2 : 1) : 0;
        }
        case UP_ADD:
        {
            return 1;
        }
        case UP_SHARE:
        {
            return self.allowsActions ? 1 : 0;
        }
        default:
        {
            return 0;
        }
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
    [[cell textLabel] setTextColor:FONT_COLOR_LABEL];
    [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:13]];
    
    switch (indexPath.section)
    {
        case UP_FILLER:
        {
            [cell setHidden:YES];
            break;
        }
        case UP_EMAIL:
        {
            [cell.textLabel setText:emailAddress];
            break;
        }
        case UP_CONTACT:
        {
            if (indexPath.row == 0)
            {
                [[cell textLabel] setText:NSLocalizedString(@"UCT_CALL", @"")];
            }
            else if (indexPath.row == 1)
            {
                [[cell textLabel] setText:NSLocalizedString(@"UCT_SEND_MESSAGE", @"")];
            }
            break;
        }
        case UP_ADD:
        {
            [[cell textLabel] setText:NSLocalizedString(@"UCT_ADD", @"")];
            break;
        }
        case UP_SHARE:
        {
            if (indexPath.row == 0)
            {
                [[cell textLabel] setText:NSLocalizedString(@"BL_SHARE_CONTACT", @"")];
            }
            break;
        }
        default:
            break;
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //If we're editing, clear some space for the name label
    if (!self.tableView.isEditing && indexPath.section == CC_FILLER)
    {
        return tableHeaderSize;
    }
    else
    {
        return SIZE_CELL_HEIGHT;
    }
}

//Clear tableview header and footer-height to make sure hidden sections don't take up space
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    //In case of the filler, no header
    if (section == CC_FILLER || [self tableView:self.tableView numberOfRowsInSection:section] == 0)
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
    //In case of the filler, no footer
    if (section == CC_FILLER || [self tableView:self.tableView numberOfRowsInSection:section] == 0)
    {
        return 0.1f;
    }
    else
    {
        return UITableViewAutomaticDimension;
    }
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    //Determine if we should take action
    BOOL takeAction = YES;
    if (unknownPersonViewDelegate != nil)
    {
        ABPropertyID propertyID = 0;
        ABMultiValueIdentifier multiRefIdentifier = 0;
        if (indexPath.section == UP_EMAIL)
        {
            propertyID = kABPersonEmailProperty;
            multiRefIdentifier = ((ABRecordCopyValue(self.contact.contactRef, propertyID)), (int)indexPath.row);
        }
        else if (indexPath.section == UP_CONTACT && indexPath.row == 0)
        {
            propertyID = kABPersonPhoneProperty;
            multiRefIdentifier = ABMultiValueGetIdentifierAtIndex((ABRecordCopyValue(self.contact.contactRef, propertyID)), indexPath.row);
        }
        
        //Determine the action
        [unknownPersonViewDelegate unknownPersonViewController:self shouldPerformDefaultActionForPerson:self.contact.contactRef property:propertyID identifier:multiRefIdentifier];
    }
 
    if (takeAction)
    {
        switch (indexPath.section)
        {
            case UP_CONTACT:
                if (indexPath.row == 0)
                {
                    [NBContact makePhoneCall:number withContactID:nil];

                    if ([self isKindOfClass:[NBRecentUnknownContactViewController class]])
                    {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                                       dispatch_get_main_queue(), ^
                        {
                            [self.navigationController popToRootViewControllerAnimated:NO];
                        });
                    }
                }
                break;

            case UP_EMAIL:
#warning - Add your own implementation
                break;

            case UP_ADD:
            {
                [[NBAddressBookManager sharedManager] addNumber:[personRepresentation string]
                                                toContactAsType:@"typje"
                                                 viewController:self];
                break;
            }
            case UP_SHARE:
#warning - Add your own implementation here
                break;
        }
    }
}

@end
