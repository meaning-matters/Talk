//
//  NBPeopleListViewController.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/1/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NBPersonViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "NSMutableString+Appending.h"
#import "NBAddressBookManager.h"
#import "NBGroupsManager.h"
#import "NBGroupsTableViewController.h"
#import "NBPeoplePickerNavigationControllerDelegate.h"
#import "NBPeopleTableViewCell.h"

#define SECTION_TITLES @[@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z", @"#"]

@interface NBPeopleListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchDisplayDelegate, UISearchBarDelegate>
{
    //Section title management
    BOOL hasEnoughContactsForSectionTitles;
    
    //Datasource with all contacts, containing 27 arrays (a-z + #)
    NSMutableArray * allContacts;
    NSMutableArray * contactsDatasource;
    
    //The search bar parameters
    NSMutableArray * filteredContacts;
    NSString * searchString;
    
    //Wether we're in filter-view
    BOOL filterEnabled;
    
    //The groups in the system
    NBGroupsManager * groupsManager;
    
    //Label in case there are no contacts
    UILabel * noContactsLabel;
    
    //Last label in the view, showing the number of contacts
    UILabel * numContactsLabel;
    
    //Indicate we scrolled to top
    BOOL scrolledToTop;
    
    //The selected index to deanimate
    NSIndexPath * selectedIndexPath;
    
    //The active viewcontroller
    NBPersonViewController * personViewController;
}

//Handle on the table header, number label and table view
@property (nonatomic) UIView*                     tableHeader;
@property (nonatomic) UILabel*                    myNumberLabel;
@property (nonatomic, weak) IBOutlet UITableView* tableView;

//Variables used to merge a contact with a new one
@property (strong, nonatomic) NBContact * contactToMergeWith;

@property (nonatomic) id<NBRelatedPersonDelegate> relatedPersonDelegate;

//@property (nonatomic, strong) UISearchDisplayController *contactSearchDisplayController;

/*#####
//Delegate called when adding a contact is completed
@property (nonatomic, assign) id<NBNewPersonViewControllerDelegate> aNewPersonViewDelegate;
*/

//Flag to indicate we are merely selecting a name from the list
@property (nonatomic) BOOL amSelectingName;

//Make this method publicly available so we can set the cancel-button when selecting a related person
- (void)cancelPressed;

- (void)findContactsHavingNumber:(NSString*)number completion:(void(^)(NSArray* contactIds))completion;

- (NSString*)contactNameForId:(NSString*)contactId;

@end
