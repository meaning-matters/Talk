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

@property (nonatomic, strong) NSManagedObjectContext*     managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController* fetchedMessagesController;
@property (nonatomic, strong) NSMutableArray*             contactSearchResults;
@property (nonatomic, strong) NSString*                   searchBarContent;

@end


@implementation NewConversationViewController

- (instancetype)initWithManagedObjectContact:(NSManagedObjectContext*)managedObjectContext
                   fetchedMessagesController:(NSFetchedResultsController*)fetchedMessagesController
{
    if (self = [super init])
    {
        self.managedObjectContext      = managedObjectContext;
        self.fetchedMessagesController = fetchedMessagesController;
    }
    
    return self;
}


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
    PhoneNumber* numberE164 = [[PhoneNumber alloc] initWithNumber:@"34668690178"]; // @TODO: Get default SMS number, or a selection-popup or something ???
    PhoneNumber* externE164 = [[PhoneNumber alloc] initWithNumber:@"31683378285"]; // @TODO: Get number of selected contact (select of multiple?) or the typed number.
    NSString*    contactId  = @"23"; // @TODO: Get contactId for selected contact or nil
    
    ConversationViewController* viewController = [[ConversationViewController alloc] initWithManagedObjectContext:self.managedObjectContext
                                                                                        fetchedMessagesController:self.fetchedMessagesController
                                                                                                       numberE164:numberE164
                                                                                                       externE164:externE164
                                                                                                        contactId:contactId];
    
    
//    PhoneNumber* phoneNumber  = [[PhoneNumber alloc] initWithNumber:message.externE164];
//    viewController.externE164 = [phoneNumber e164Format];
    
//    [phoneNumber setNumber:message.numberE164];
//    viewController.numberE164 = [phoneNumber e164Format];
    
//    viewController.contactId  = message.contactId;
    
//    PhoneNumber* number = [[PhoneNumber alloc] initWithNumber:self.searchBarContent];
//
//    if (self.contactSearchResults.count > 0) // If there are search-results
//    {
//        // Get number for contact at indexPath
//    }
//    else if ([number isValid]) // If entered number is valid
//    {
//        // Use typed number
//    }
//    else
//    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
//    }
    
    [self.navigationController pushViewController:viewController animated:YES];
}


- (void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)searchText
{
    self.searchBarContent = searchText;
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
