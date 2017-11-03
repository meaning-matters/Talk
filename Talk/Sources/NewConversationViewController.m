//
//  NewConversationViewController.m
//  Talk
//
//  Created by Jeroen Kooiker on 03/11/2017.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import "NewConversationViewController.h"
#import "AppDelegate.h"
#import "ConversationViewController.h"

@interface NewConversationViewController ()

@property (nonatomic, strong) NSMutableArray* contactSearchResults;

@end


@implementation NewConversationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"new message"; // @TODO: Change...
    
    self.contactSearchResults = [[NSMutableArray alloc] init];
    [self createIndexOfWidth:0];
    
    self.tableView = self.searchDisplayController.searchResultsTableView;
    self.searchDisplayController.searchBar.delegate = self;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    // If there are no results, return 1 so we can show a cell to write a message to this number.
    // @TODO: add logic to check if there is actually a valid number to send a message to.
    if (!self.contactSearchResults.count)
    {
        return 1;
    }
    else
    {
        return self.contactSearchResults.count;
    }
}


- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"ContactsSearchResultCell"];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ContactsSearchResultCell"];
    }
    if (!self.contactSearchResults.count)
    {
        NSLog(@"No results, but 1.....");
        cell.textLabel.text = @"new message to ...";
    }
    else
    {
        cell.textLabel.text = self.contactSearchResults[indexPath.row][1];
    }
    
    return cell;
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    ConversationViewController* viewController = [ConversationViewController messagesViewController];
    viewController.managedObjectContext        = self.managedObjectContext;
    viewController.fetchedMessagesController   = self.fetchedMessagesController;
    
//    PhoneNumber* phoneNumber  = [[PhoneNumber alloc] initWithNumber:message.externE164];
//    viewController.externE164 = [phoneNumber e164Format];
    
//    [phoneNumber setNumber:message.numberE164];
//    viewController.numberE164 = [phoneNumber e164Format];
    
//    viewController.contactId  = message.contactId;
    
    [self.navigationController pushViewController:viewController animated:YES];
}


- (void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)searchText
{
    self.contactSearchResults = [[NSMutableArray alloc] init];
    [[[AppDelegate appDelegate] nBPeopleListViewController] filterContactsWithSearchString:searchText completion:^(NSArray* contacts)
    {
        for (int i = 0; i < contacts.count; i++)
        {
            ABRecordRef contact = (__bridge ABRecordRef)[contacts objectAtIndex:i];
            NSString*   contactId   = [NSString stringWithFormat:@"%d", ABRecordGetRecordID(contact)];
            NSString*   contactName = [[AppDelegate appDelegate] contactNameForId:contactId];
            NSArray*    contactInfo = @[contactId, contactName];
            [self.contactSearchResults addObject:contactInfo];
        }
        dispatch_async(dispatch_get_main_queue(),^
        {
            [self.tableView reloadData];
        });
    }];
}

@end
