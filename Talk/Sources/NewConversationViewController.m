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
    
    if (self.contactSearchResults.count > 0) // @TODO: Check if the entered number is valid
    {
        // @TODO: Check if all numbers are valid ... where the data is inserted in array before reloading table.
        cell.textLabel.text = self.contactSearchResults[indexPath.row][1];
    }
    else if (self.searchBarContent.length > 0) // @TODO: Check if number is valid.
    {
        cell.textLabel.text = [NSString stringWithFormat:@"Send message to %@", self.searchBarContent]; // @TODO: LocalizedString ??
    }
    else
    {
        // @TODO: Message that there are no search results
    }
    
    return cell;
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    PhoneNumber* numberE164 = [[PhoneNumber alloc] initWithNumber:@"34668690178"]; // @TODO: Get default SMS number, or a selection-popup or something ???
    PhoneNumber* externE164;

    // @TODO: for all: make sure number supports SMS.
    if (self.contactSearchResults.count > 0) // If there are search-results
    {
        // @TODO: If contact doesn't have any numbers, show popup.
        
        NSString* contactId = self.contactSearchResults[indexPath.row][0];
        
        // Get all numbers for contact.
        ABRecordID      recordId     = [contactId intValue];
        ABRecordRef     contact      = ABAddressBookGetPersonWithRecordID([[NBAddressBookManager sharedManager] getAddressBook], recordId);
        ABMultiValueRef phones       = ABRecordCopyValue(contact, kABPersonPhoneProperty);
        NSArray*        phoneNumbers = (NSArray*)CFBridgingRelease(ABMultiValueCopyArrayOfAllValues(phones));
        
        for (int i = 0; i < phoneNumbers.count; i++)
        {
            CFStringRef numberLabelRef = ABMultiValueCopyLabelAtIndex(phones, i);
            NSString*   numberLabel    = (__bridge NSString*)ABAddressBookCopyLocalizedLabel(numberLabelRef);
            NSLog(@"%@  %@", numberLabel, phoneNumbers[i]);
        }
        
        // @TODO: Let user select number if there is more than one.
        // @TODO: Make sure formatting always works, otherwise don't display the number.
        externE164 = [[PhoneNumber alloc] initWithNumber:phoneNumbers[0]];
        
        ConversationViewController* viewController = [[ConversationViewController alloc] initWithManagedObjectContext:self.managedObjectContext
                                                                                            fetchedMessagesController:self.fetchedMessagesController
                                                                                                           numberE164:numberE164
                                                                                                           externE164:externE164
                                                                                                            contactId:contactId];
        
        [self.navigationController pushViewController:viewController animated:YES];
    }
    else if (true) // @TODO: Check if entered number is valid.
    {
        // @TODO: Make sure typed number is valid and formatting works.
        externE164 = [[PhoneNumber alloc] initWithNumber:self.searchBarContent];
        
        NSString* contactId; // @TODO: What to do with contactId here, nil? (since not in contacts)
        
        ConversationViewController* viewController = [[ConversationViewController alloc] initWithManagedObjectContext:self.managedObjectContext
                                                                                            fetchedMessagesController:self.fetchedMessagesController
                                                                                                           numberE164:numberE164
                                                                                                           externE164:externE164
                                                                                                            contactId:contactId];
        
        [self.navigationController pushViewController:viewController animated:YES];
    }
    else
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}


- (void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)searchText
{
    self.searchBarContent          = searchText;
    self.contactSearchResults      = [[NSMutableArray alloc] init];
    
    [[[AppDelegate appDelegate] nBPeopleListViewController] filterContactsWithSearchString:searchText completion:^(NSArray* contacts)
    {
        for (int i = 0; i < contacts.count; i++)
        {
            ABRecordRef contact = (__bridge ABRecordRef)[contacts objectAtIndex:i];
            NSString*   contactId   = [NSString stringWithFormat:@"%d", ABRecordGetRecordID(contact)];
            NSString*   contactName = [[AppDelegate appDelegate] contactNameForId:contactId];
            NSArray*    contactInfo = [NSArray arrayWithObjects:contactId, contactName, nil];
            [self.contactSearchResults addObject:contactInfo];
        }
        dispatch_async(dispatch_get_main_queue(),^
        {
            [self.tableView reloadData];
        });
    }];
}

@end
