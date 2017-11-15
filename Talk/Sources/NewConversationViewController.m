//
//  NewConversationViewController.m
//  Talk
//
//  Created by Jeroen Kooiker on 03/11/2017.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import "NewConversationViewController.h"
#import "AppDelegate.h"

@interface NewConversationViewController ()

@property (nonatomic, strong) NSManagedObjectContext*     managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController* fetchedMessagesController;
@property (nonatomic, strong) NSMutableArray*             contactSearchResults;
@property (nonatomic, strong) NSString*                   searchBarContent;
@property (nonatomic, strong) UILabel*                    noSearchResultsLabel;

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
    
    self.title = @"New Message"; // @TODO: Change...
    
    self.contactSearchResults = [[NSMutableArray alloc] init];
    [self createIndexOfWidth:0];
    
    self.tableView = self.searchDisplayController.searchResultsTableView;
    self.searchDisplayController.searchBar.delegate = self;
    
    // Label that is shown when there are no search results.
    self.noSearchResultsLabel               = [[UILabel alloc] initWithFrame:CGRectMake(0, 0,
                                                                                        self.tableView.bounds.size.width,
                                                                                        self.tableView.bounds.size.height)];
    self.noSearchResultsLabel.text          = @"No contacts found"; // @TODO: LocalizedString
    self.noSearchResultsLabel.textColor     = [UIColor blackColor];
    self.noSearchResultsLabel.textAlignment = NSTextAlignmentCenter;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    // If there are search results.
    if (self.contactSearchResults.count)
    {
        return self.contactSearchResults.count;
    }
    // If there are no search results, but the entered number is valid.
    else if (!self.contactSearchResults.count && false) // @TODO: check if entered number is valid.
    {
        return 1;
    }
    // If there are no search results.
    else
    {
        // @TODO: Insert label that there are no search results.
        return 0;
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
    // If there are search results.
    if (self.contactSearchResults.count > 0)
    {
        NSString* contactId = self.contactSearchResults[indexPath.row][0];
        
        // Get all phonenumbers for the selected contact.
        ABRecordID      recordId     = [contactId intValue];
        ABRecordRef     contact      = ABAddressBookGetPersonWithRecordID([[NBAddressBookManager sharedManager] getAddressBook], recordId);
        ABMultiValueRef phones       = ABRecordCopyValue(contact, kABPersonPhoneProperty);
        NSArray*        phoneNumbers = (NSArray*)CFBridgingRelease(ABMultiValueCopyArrayOfAllValues(phones));
        
        // If the contact doesn't have any phonenumbers -> show an alert saying this.
        if ([phoneNumbers count] == 0)
        {
            // @TODO: NSLocalizedString
            UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"No numbers"
                                                                                     message:@"This contact has no phone numbers. Please choose another one."
                                                                              preferredStyle:UIAlertControllerStyleAlert];
            // @TODO: NSLocalizedString
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction* action)
            {
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            }];
            
            [alertController addAction:defaultAction];
            [self presentViewController:alertController animated:YES completion:^(void){}];
        }
        // If the contact has one phonenumber -> use this phonenumber.
        else if ([phoneNumbers count] == 1)
        {
            PhoneNumber* externE164 = [[PhoneNumber alloc] initWithNumber:phoneNumbers[0]];
            
            [self pushToConversationViewControllerWithExternE164:externE164 contactId:contactId];
        }
        // If the contact has multiple phonenumbers -> show an actionsheet to choose one.
        else if ([phoneNumbers count] > 1)
        {
            [self.searchBar resignFirstResponder];
            
            // @TODO: Localized strings
            UIAlertController* alertController = [UIAlertController alertControllerWithTitle:self.contactSearchResults[indexPath.row][1]
                                                                                     message:@"This contact has multiple numbers. Choose one"
                                                                              preferredStyle:UIAlertControllerStyleActionSheet];
            
            UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                                   style:UIAlertActionStyleCancel
                                                                 handler:^(UIAlertAction* action)
            {
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            }];
            
            [alertController addAction:cancelAction];

            for (int i = 0; i < [phoneNumbers count]; i++)
            {
                CFStringRef numberLabelRef = ABMultiValueCopyLabelAtIndex(phones, i);
                NSString*   numberLabel    = (__bridge NSString*)ABAddressBookCopyLocalizedLabel(numberLabelRef);
                
                PhoneNumber* externE164 = [[PhoneNumber alloc] initWithNumber:phoneNumbers[i]];
                
                // @TODO: Should we display the phonenumber like this, or in its original state (as is saved in the contacts)?
                UIAlertAction* selectNumberAction = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%@ (%@)", [externE164 internationalFormat], numberLabel]
                                                                             style:UIAlertActionStyleDefault
                                                                           handler:^(UIAlertAction* action)
                {
                    [self pushToConversationViewControllerWithExternE164:externE164 contactId:contactId];
                }];
                
                [alertController addAction:selectNumberAction];
            }
            
            [self presentViewController:alertController animated:YES completion:^(void){}];
        }
    }
    else if (true) // If there are no search results, but a valid number is entered.
    {
        // @TODO: Make sure typed number is valid and formatting works.
        PhoneNumber* externE164 = [[PhoneNumber alloc] initWithNumber:self.searchBarContent];
        
        NSString* contactId; // @TODO: What to do with contactId here, nil? (since not in contacts)
        
        [self pushToConversationViewControllerWithExternE164:externE164 contactId:contactId];
    }
    else // If there are no search results.
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}


- (void)pushToConversationViewControllerWithExternE164:(PhoneNumber*)externE164 contactId:(NSString*)contactId
{
    // @TODO: In the next version this screen should get its own number from VoncerSationsViewController.!!!
    PhoneNumber* numberE164 = [[PhoneNumber alloc] initWithNumber:@"34668690178"];
    
    ConversationViewController* viewController = [[ConversationViewController alloc] initWithManagedObjectContext:self.managedObjectContext
                                                                                        fetchedMessagesController:self.fetchedMessagesController
                                                                                                       numberE164:numberE164
                                                                                                       externE164:externE164
                                                                                                        contactId:contactId];
    
    // Scroll to the row with the existing chat.
    int rowToScrollTo = [self.conversationsViewcontroller indexForChatWithExternE164:[externE164 e164Format]];
    [self.conversationsViewcontroller.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:rowToScrollTo inSection:0]
                                                      atScrollPosition:UITableViewScrollPositionMiddle
                                                              animated:YES];
    
    // Add the ConversationController to the ViewControllers array of ConversationsViewController.
    NSMutableArray* viewControllers = [NSMutableArray arrayWithArray:self.conversationsViewcontroller.navigationController.viewControllers];
    [viewControllers addObject:viewController];

    // Dismiss the NavigationController in which the NewConversationController is embedded.
    [self.conversationsViewcontroller.writeMessageNavigationController dismissViewControllerAnimated:YES completion:^(void)
    {
        // Set the ViewControllers array of ConversationsViewController, with the newly added ConversationViewcontroller.
        [self.conversationsViewcontroller.navigationController setViewControllers:viewControllers animated:YES];
    }];
}


- (void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)searchText
{
    self.searchBarContent     = searchText;
    self.contactSearchResults = [[NSMutableArray alloc] init];
    
    [[[AppDelegate appDelegate] nBPeopleListViewController] filterContactsWithSearchString:searchText completion:^(NSArray* contacts)
    {
        for (int i = 0; i < contacts.count; i++)
        {
            ABRecordRef contact     = (__bridge ABRecordRef)[contacts objectAtIndex:i];
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


// @TODO:
// - bij 1 nummer meteen doorgaan
// - nieuwe conversation van onder (met cancel-button, volgende pagina gaat terug naar root viewcontroller)



@end
