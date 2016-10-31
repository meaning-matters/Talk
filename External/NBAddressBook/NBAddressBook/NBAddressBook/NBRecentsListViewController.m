//
//  NBRecentsListViewController.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/18/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "NBRecentsListViewController.h"
#import "NBTestDelegate.h"
#import "Strings.h"
#import "AppDelegate.h"
#import "PhoneNumber.h"
#import "DataManager.h"
#import "WebClient.h"
#import "Settings.h"

@interface NBRecentsListViewController ()
{
    NSManagedObjectContext*               managedObjectContext;
    NSFetchedResultsController*           fetchedResultsController;

    NBRecentUnknownContactViewController* recentUnknownViewController;
    NBRecentContactViewController*        recentViewController;

    //The missed-calls only predicate
    NSPredicate*                          missedCallsOnlyPredicate;
    
    NSDate*                               reloadDate;
}

@end


@implementation NBRecentsListViewController

- (instancetype)init
{
    return [self initWithManagedObjectContext:[DataManager sharedManager].managedObjectContext];
}

#pragma mark - Initialization
- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContextParam
{
    if (self = [super init])
    {
        self.title = [Strings recentsString];
        // The tabBarItem image must be set in my own NavigationController.

        managedObjectContext = managedObjectContextParam;

        //Listen for reloads
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doLoad) name:NF_RELOAD_CONTACTS object:nil];
    }

    return self;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)doLoad
{
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [self.tableView reloadData];
    });
}


//### Not used.
- (void)findContactsForAnonymousItems
{
    for (NSArray* recents in dataSource)
    {
        CallRecordData* recent = recents[0];
        if (recent.contactID == nil)
        {
            PhoneNumber* phoneNumber = [[PhoneNumber alloc] initWithNumber:recent.e164];
            [[AppDelegate appDelegate] findContactsHavingNumber:[phoneNumber nationalDigits]
                                                     completion:^(NSArray* contactIds)
            {
                if (contactIds.count == 1)
                {
                    for (CallRecordData* entry in recents)
                    {
                        recent.contactID = contactIds[0];
                    }
                }
            }];
        }
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    //Set the segmented control
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[NSLocalizedString(@"CNT_ALL", @""), NSLocalizedString(@"CNT_MISSED", @"")]];
    [segmentedControl setSelectedSegmentIndex:0];
    [segmentedControl setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    segmentedControl.frame = CGRectMake(0, 0, 150, 30);
    [segmentedControl addTarget:self action:@selector(segmentedControlSwitched:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = segmentedControl;

    //Set the modify-button
    editButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(modifyListPressed)];
    doneButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed)];
    clearButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"CNT_CLEAR", @"")
                                                   style:UIBarButtonItemStylePlain
                                                  target:self
                                                  action:@selector(clearAllPressed)];
    
    //Create the action sheet
    clearActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"NCT_CANCEL", @"")
                                     destructiveButtonTitle:nil
                                          otherButtonTitles:NSLocalizedString(@"CNT_CLEAR_WEEK",  @""),
                                                            NSLocalizedString(@"CNT_CLEAR_MONTH", @""),
                                                            NSLocalizedString(@"CNT_CLEAR_ALL",   @""), nil];

    [clearActionSheet setActionSheetStyle:UIActionSheetStyleBlackTranslucent];

    //The datasource
    dataSource = [NSMutableArray array];
    
    //Create the missed calls only predicate
    missedCallsOnlyPredicate = [NSPredicate predicateWithFormat:@"(status == %d)", CallStatusMissed];
    
    //Load in the initial content
    [self performFetch];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reload)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];

    UIRefreshControl* refreshControl = [[UIRefreshControl alloc] init];
    NSString* title = NSLocalizedString(@"Check for incoming calls", @"");
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:title];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self reload];

    //### Workaround: http://stackoverflow.com/a/19126113/1971013
    //### And it also fixes my own issue: http://stackoverflow.com/a/22626388/1971013
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [self.refreshControl beginRefreshing];
        [self.refreshControl endRefreshing];
    });
}


- (void)refresh:(id)sender
{
    NSDate* date = [Settings sharedSettings].recentsCheckDate;
    [[WebClient sharedClient] retrieveInboundCallRecordsFromDate:date reply:^(NSError *error, NSArray *records)
    {
        [Settings sharedSettings].recentsCheckDate = [NSDate date];

        [self.tableView beginUpdates];
        [self processInboundCallRecords: records];
        [self.tableView endUpdates];

        [sender endRefreshing];
    }];
}


- (void)processInboundCallRecords:(NSArray*)records
{

}


#pragma mark - Replacing an unknown contact with a known one
- (void)replaceViewController:(UIViewController*)viewController
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void)
    {
        [self.navigationController popViewControllerAnimated:NO];
        [self.navigationController pushViewController:viewController animated:NO];
    });
}

#pragma mark - Clear all recents
- (void)clearAllPressed
{
    //Present the actionsheet
    [clearActionSheet showFromTabBar:[[self.navigationController tabBarController] tabBar]];
}


- (void)clearOneWeekRecents
{
    NSCalendar*       calendar    = [NSCalendar currentCalendar];
    NSDateComponents* components  = [NSDateComponents new];
    components.weekOfYear         = -1; // This also works for first week of the year.
    NSDate*           weekAgoDate = [calendar dateByAddingComponents:components toDate:[NSDate date] options:0];

    // Clear all the old objects
    missedCallsOnly = NO;
    [self performFetch];
    for (CallRecordData* entry in [fetchedResultsController fetchedObjects])
    {
        if ([entry.date compare:weekAgoDate] == NSOrderedAscending)
        {
            [managedObjectContext deleteObject:entry];
        }
    }

    [managedObjectContext save:nil];
}


- (void)clearOneMonthRecents
{
    NSCalendar*       calendar    = [NSCalendar currentCalendar];
    NSDateComponents* components  = [NSDateComponents new];
    components.month              = -1; // This also works for first month of the year.
    NSDate*          monthAgoDate = [calendar dateByAddingComponents:components toDate:[NSDate date] options:0];

    // Clear all the old objects
    missedCallsOnly = NO;
    [self performFetch];
    for (CallRecordData* entry in [fetchedResultsController fetchedObjects])
    {
        if ([entry.date compare:monthAgoDate] == NSOrderedAscending)
        {
            [managedObjectContext deleteObject:entry];
        }
    }

    [managedObjectContext save:nil];
}

- (void)clearAllRecents
{
    // Clear all the old objects
    missedCallsOnly = NO;
    [self performFetch];
    for (CallRecordData* entry in [fetchedResultsController fetchedObjects])
    {
        [managedObjectContext deleteObject:entry];
    }

    [managedObjectContext save:nil];
}

#pragma mark - Action sheet delegate

- (void)willPresentActionSheet:(UIActionSheet*)actionSheet
{
    int      count       = 0;
    UIColor* deleteColor = [[NBAddressBookManager sharedManager].delegate deleteTintColor];
    UIColor* tintColor   = [[NBAddressBookManager sharedManager].delegate tintColor];
    for (UIView* subview in actionSheet.subviews)
    {
        if ([subview isKindOfClass:[UIButton class]])
        {
            UIButton* button = (UIButton*)subview;
            UIColor*  color  = (count++ < 3) ? deleteColor : tintColor;

            [button setTitleColor:color forState:UIControlStateHighlighted];
            [button setTitleColor:color forState:UIControlStateNormal];
            [button setTitleColor:color forState:UIControlStateSelected];
        }
    }
}


- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //Only used to clear the list
    switch (buttonIndex)
    {
        case 0:
        {
            [self clearOneWeekRecents];
            [self reload];
            break;
        }
        case 1:
        {
            [self clearOneMonthRecents];
            [self reload];
            break;
        }
        case 2:
        {
            //Clear up the system
            [self clearAllRecents];
            [dataSource removeAllObjects];
            break;
        }
    }

    if (buttonIndex != 3)
    {
        //Stop editing
        [self.navigationItem setLeftBarButtonItem:nil];
        [self.navigationItem setRightBarButtonItem:nil];
        [self donePressed];
    }
}


#pragma mark - Loading recent calls from CoreData

- (void)reload
{
    // Only perform a full reload if more calls were made or when it's the next day.
    NSCalendar* calendar          = [NSCalendar currentCalendar];
    NSArray*    allRecentContacts = [self.fetchedResultsController fetchedObjects];
    
    if (numRecentCalls == 0 || [allRecentContacts count] != numRecentCalls ||
        ![calendar isDate:[NSDate date] inSameDayAsDate:reloadDate])
    {
        reloadDate = [NSDate date];
        
        //Performance improvement
        numRecentCalls = (int)[allRecentContacts count];
        
        //Group the recent contacts into a datasource
        [dataSource removeAllObjects];
        CallRecordData* lastEntry;
        NSMutableArray* entryArray;
        for (CallRecordData* entry in allRecentContacts)
        {
            //If we don't have a last entry or it doesn't match the record or number, create a new entry
            BOOL entryAdded = NO;
            if (lastEntry != nil)
            {
                //If we have the same contact,
                //the same unknown number,
                //or are a missed call same as the last entry
                if (( [lastEntry.contactID isEqualToString:entry.contactID] ||
                    ( lastEntry.contactID == nil && entry.contactID == nil && [lastEntry.number isEqualToString:entry.number])) &&
                    ( ( [lastEntry.status intValue] == CallStatusMissed && [entry.status intValue] == CallStatusMissed) ||
                    ( [lastEntry.status intValue] != CallStatusMissed && [entry.status intValue] != CallStatusMissed)))
                {
                    //If the last entry's day is equal to this day
                    if ([calendar isDate:lastEntry.date inSameDayAsDate:entry.date])
                    {
                        [entryArray addObject:entry];
                        entryAdded = YES;
                    }
                }
            }
            
            //If we haven't added the entry to the last group, add it now
            if (!entryAdded)
            {
                entryArray = [NSMutableArray array];
                [entryArray addObject:entry];   
                [dataSource addObject:entryArray];
            }
            
            //Remember for the next check
            lastEntry = entry;
        }
        
        //If we have more than one contact, show the edit button
        if ([allRecentContacts count] > 0 && !self.tableView.editing)
        {
            [self.navigationItem setRightBarButtonItem:editButton];
        }
        
        //Animate in/out the rows
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}


#pragma mark - Segmented control change
- (void)segmentedControlSwitched:(UISegmentedControl*)control
{
    //End editing
    [self donePressed];
    
    //Check to see what to display
    missedCallsOnly = control.selectedSegmentIndex == 1;
    [self performFetch];
}

#pragma mark - Modifying the table
- (void)modifyListPressed
{
    //Shift all the labels in view
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:ANIMATION_SPEED];
    NSArray * visiblePaths = [self.tableView indexPathsForVisibleRows];
    for (NSIndexPath *indexPath in visiblePaths)
    {
        NBRecentCallCell * missedCallCell = (NBRecentCallCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        [missedCallCell shiftLabels:YES];
    }

    [UIView commitAnimations];
    
    //Set the buttons accordingly
    [self.navigationItem setLeftBarButtonItem:clearButton];
    [self.navigationItem setRightBarButtonItem:doneButton];
    [self.tableView setEditing:YES animated:YES];
}

- (void)donePressed
{
    //Restore all the labels in view
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:ANIMATION_SPEED];
    NSArray * visiblePaths = [self.tableView indexPathsForVisibleRows];
    for (NSIndexPath *indexPath in visiblePaths)
    {
        NBRecentCallCell * missedCallCell = (NBRecentCallCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        [missedCallCell halfLabelFrames:NO];
        [missedCallCell shiftLabels:NO];
    }
    [UIView commitAnimations];
    
    [self.navigationItem setLeftBarButtonItem:nil];
    if ([dataSource count] > 0)
    {
        [self.navigationItem setRightBarButtonItem:editButton];
    }
    else
    {
        [self.navigationItem setRightBarButtonItem:nil];
    }
    
    [self.tableView setEditing:NO animated:YES];
}

#pragma mark - Tableview datasource methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [dataSource count];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSArray*          entryRowArray  = [dataSource objectAtIndex:indexPath.row];
    static NSString*  CellIdentifier = @"Cell";

    NBRecentCallCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[NBRecentCallCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleDefault];
        
        //Add a number label
        UILabel * numberLabel = [[UILabel alloc]initWithFrame:CGRectMake(POSITION_NUMBER_LABEL,
                                                                         4,
                                                                         SIZE_NUMBER_LABEL,
                                                                         20)];
        [numberLabel setBackgroundColor:[UIColor clearColor]];
        [numberLabel setFont:[UIFont boldSystemFontOfSize:16]];
        [cell setNumberLabel:numberLabel];
        [cell addSubview:numberLabel];

        // Add an outgoing-call imageview
        UIImageView * outgoingImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"outgoingCall"]];
        [outgoingImageView setFrame:CGRectMake(0, 0, 10, 10)];
        [outgoingImageView setHidden:YES];
        [cell setOutgoingCallImageView:outgoingImageView];
        [cell addSubview:outgoingImageView];

        // Add a number type label
        UILabel* typeLabel = [[UILabel alloc]initWithFrame:CGRectMake(POSITION_NUMBER_LABEL,
                                                                      22,
                                                                      SIZE_NUMBER_LABEL,
                                                                      20)];
        [typeLabel setBackgroundColor:[UIColor clearColor]];
        [typeLabel setFont:[UIFont systemFontOfSize:13]];
        [typeLabel setTextColor:[UIColor grayColor]];
        [cell setNumberTypeLabel:typeLabel];
        [cell addSubview:typeLabel];
    }

    // Set the number and description
    UILabel* numberLabel = cell.numberLabel;
    UILabel* numberType  = cell.numberTypeLabel;

    CallRecordData* latestEntry = [entryRowArray objectAtIndex:0];
    ABRecordRef           contact;
    if (latestEntry.contactID != nil)
    {
        contact = [self getContactForID:latestEntry.contactID];
        if (contact == nil)
        {
            // Contact appears to be gone, clear it.
            for (CallRecordData* entry in entryRowArray)
            {
                entry.contactID = nil;
            }
        }
    }

    if (latestEntry.contactID != nil)
    {
        // Set the name
        NSString* representation = [[NBContact getListRepresentation:contact] string];
        [numberLabel setText:representation];

        numberType.text = nil;

        // Determine and set the label
        ABMultiValueRef* datasource = (ABMultiValueRef*)ABRecordCopyValue(contact, kABPersonPhoneProperty);
        for (CFIndex i = 0; i < ABMultiValueGetCount(datasource); i++)
        {
            NSString* number = (__bridge NSString*)(ABMultiValueCopyValueAtIndex(datasource, i));

            if ([[NBAddressBookManager sharedManager].delegate matchRecent:latestEntry withNumber:number])
            {
                [numberType setText:(__bridge NSString*)ABAddressBookCopyLocalizedLabel((ABMultiValueCopyLabelAtIndex(datasource, i)))];

                break;
            }
        }
    }
    else
    {
        NSString* number = latestEntry.number;
        number = [[NBAddressBookManager sharedManager].delegate formatNumber:latestEntry.number];
        [numberLabel setText:number];
        [numberType setText:NSLocalizedString(@"LBL_UNKNOWN", @"")];
    }
    
    if ([latestEntry.status intValue] == CallStatusMissed)
    {
        [numberLabel setTextColor:[UIColor colorWithRed:187/255.0f green:25/255.0f blue:25/255.0f alpha:1.0f]];
    }
    else
    {
        [numberLabel setTextColor:[UIColor blackColor]];
    }
    
    //Set the amount of calls made (incoming + outgoing)
    if ([entryRowArray count] > 1)
    {
        //Set the last part as greyed out regular
        NSMutableAttributedString* attributedName = [[NSMutableAttributedString alloc]
                                                     initWithString:[NSString stringWithFormat:@"%@ (%lu)", numberLabel.text, (unsigned long)[entryRowArray count]]
                                                     attributes:[NSDictionary dictionaryWithObjectsAndKeys:numberLabel.font, NSFontAttributeName, nil]];

        [attributedName setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                       [UIFont systemFontOfSize:16],
                                       NSFontAttributeName,
                                       [UIColor grayColor],
                                       NSForegroundColorAttributeName,nil]
                                range:NSMakeRange([numberLabel.text length], [attributedName length] - [numberLabel.text length])];
        [numberLabel setAttributedText:attributedName];
    }

    //Set the outgoing call icon
    UIImageView * outgoingImageView = cell.outgoingCallImageView;
    if ([latestEntry.direction intValue] == CallDirectionOutgoing)
    {
        //Show the view
        [outgoingImageView setHidden:NO];
        
        //Position the icon
        CGPoint imageCenter = numberType.center;
        CGSize labelSize = [numberType.text sizeWithFont:numberType.font
                                       constrainedToSize:numberType.frame.size
                                           lineBreakMode:NSLineBreakByWordWrapping];
        
        imageCenter.x = labelSize.width + 20;
        [cell setOutgoingCallImageViewCenter:imageCenter];
    }
    else
    {
        [outgoingImageView setHidden:YES];
    }

    // Set the time and (yesterday/day name in case of less than a week ago/date)
    NSString*         dayOrDate;
    NSCalendar*       cal         = [NSCalendar currentCalendar];
    NSDateComponents* components  = [cal components:(NSCalendarUnitYear      | NSCalendarUnitMonth |
                                                     NSCalendarUnitWeekOfYear | NSCalendarUnitDay)
                                           fromDate:latestEntry.date];
    NSDate*           entryDate   = [cal dateFromComponents:components];
    components                    = [cal components:(NSCalendarUnitYear       | NSCalendarUnitMonth |
                                                     NSCalendarUnitWeekOfYear | NSCalendarUnitDay)
                                           fromDate:[NSDate date]];
    NSDate*           currentDate = [cal dateFromComponents:components];
    int               timeDelta   = [currentDate timeIntervalSinceDate:entryDate];
    
    if (timeDelta < 60 * 60 * 24 * 7)
    {
        if (timeDelta == 0)
        {
            dayOrDate = NSLocalizedString(@"CNT_TODAY", @"");
        }
        else if (timeDelta == 60 * 60 * 24)
        {
            dayOrDate = NSLocalizedString(@"CNT_YESTERDAY", @"");
        }
        else
        {
            //Determine the day in the week
            NSCalendar*       calendar = [NSCalendar currentCalendar];
            NSDateComponents* comps    = [calendar components:NSWeekdayCalendarUnit fromDate:latestEntry.date];
            int               weekday  = (int)[comps weekday] - 1;
            
            NSDateFormatter* df = [[NSDateFormatter alloc] init];
            [df setLocale: [NSLocale currentLocale]];
            NSArray* weekdays = [df weekdaySymbols];
            dayOrDate = [weekdays objectAtIndex:weekday];
        }
    }
    else
    {
        dayOrDate = [NSString formatToSlashSeparatedDate:latestEntry.date];
    }
    
    //Set the attributed text (bold time and regular day)
    NSString*                  detailText;;
    NSMutableAttributedString* attributedText;

    detailText     = [NSString stringWithFormat:@"%@\n%@", [NSString formatToTime:latestEntry.date], dayOrDate];
    attributedText = [[NSMutableAttributedString alloc] initWithString:detailText
                                                            attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14]}];

    [attributedText setAttributes:@{NSFontAttributeName            : [UIFont boldSystemFontOfSize:14],
                                    NSForegroundColorAttributeName : FONT_COLOR_MY_NUMBER}
                            range:NSMakeRange(0, [detailText rangeOfString:@"\n"].location)];
    
    [cell.detailTextLabel setAttributedText:attributedText];
    [cell.detailTextLabel setTextAlignment:NSTextAlignmentRight];
    [cell.detailTextLabel setNumberOfLines:2];
    [cell.detailTextLabel setTextColor:[[NBAddressBookManager sharedManager].delegate tintColor]];
    [cell setAccessoryType:UITableViewCellAccessoryDetailButton];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell*)aCell forRowAtIndexPath:(NSIndexPath*)indexPath
{        
    //Set the approriate cell spacing and frame for the labels
    NBRecentCallCell* cell = (NBRecentCallCell*)aCell;
    [cell shiftLabels:self.navigationItem.rightBarButtonItem == doneButton];
}


// Override to support editing the table view.
- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        //Remove the row form the local model
        NSArray* entryArray  = [dataSource objectAtIndex:indexPath.row];
        [dataSource removeObject:entryArray];
        
        //Remove the object from coredata
        for (CallRecordData* entry in entryArray)
        {
            [self.fetchedResultsController.managedObjectContext deleteObject:entry];
        }

        [self.fetchedResultsController.managedObjectContext save:nil];

        if (dataSource.count == 0)
        {
            [self donePressed];
        }
    }
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSArray*        recents     = [dataSource objectAtIndex:indexPath.row];
    CallRecordData* firstRecent = [recents objectAtIndex:0];

    [NBContact makePhoneCall:firstRecent.number withContactID:firstRecent.contactID];

    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];    
}


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    NSArray*        recents     = [dataSource objectAtIndex:indexPath.row];
    CallRecordData* firstRecent = [recents objectAtIndex:0];
    if (firstRecent.contactID == nil)
    {
        //Load as unknown person
        recentUnknownViewController = [[NBRecentUnknownContactViewController alloc] init];
        [recentUnknownViewController setAddUnknownContactDelegate:self];

        //Set the person
        ABRecordRef contactRef = ABPersonCreate();
        
#warning - Name, number and e-mail properties of the unknown contact
        //Set a name
        //ABRecordSetValue(contactRef, kABPersonFirstNameProperty, (__bridge CFTypeRef)@"FirstName", NULL);
        //ABRecordSetValue(contactRef, kABPersonLastNameProperty, (__bridge CFTypeRef)@"LastName", NULL);
        
        //Set a message
        //[personViewController setMessage:@"Message"];
        
        //Set a number
        ABMutableMultiValueRef numberMulti = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        ABMultiValueAddValueAndLabel(numberMulti, (__bridge CFTypeRef)firstRecent.number, kABOtherLabel, NULL);
        ABRecordSetValue(contactRef, kABPersonPhoneProperty, numberMulti, nil);
        
        //Set an email
        //ABMutableMultiValueRef emailMulti = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        //ABMultiValueAddValueAndLabel(emailMulti, (__bridge CFTypeRef)@"address@email.com", kABOtherLabel, NULL);
        //ABRecordSetValue(contactRef, kABPersonEmailProperty, emailMulti, nil);
        
#warning - Set a delegate
        [recentUnknownViewController setUnknownPersonViewDelegate:nil];
        
        //Set the displayed record
        [recentUnknownViewController setDisplayedPerson:contactRef];
        
        //By default, allow adding to addressbook, but not sending messages.
        [recentUnknownViewController setAllowsAddingToAddressBook:YES];
        [recentUnknownViewController setAllowsSendingMessage:NO];
        
        [recentUnknownViewController setAllowsActions:NO];

        //Set the entry to base the calls on
        [recentUnknownViewController setRecents:recents];

        //Display the view
        [self.navigationController pushViewController:recentUnknownViewController animated:YES];
    }
    else
    {
        //Load as a contact
        recentViewController = [[NBRecentContactViewController alloc]init];
        [recentViewController setDisplayedPerson:[self getContactForID:firstRecent.contactID]];
        
        [recentViewController setAllowsActions:NO];

        //Set the entry to base the calls on
        [recentViewController setRecents:recents];

#warning - Set the cell action-delegate
        [recentViewController setPersonViewDelegate:nil];
        
        //Display the view
        [self.navigationController pushViewController:recentViewController animated:YES];
    }
}

#pragma mark - Quick contact lookup
- (ABRecordRef)getContactForID:(NSString*)contactID
{
    ABRecordID recordID = [contactID intValue];
    return ABAddressBookGetPersonWithRecordID([[NBAddressBookManager sharedManager] getAddressBook], recordID);
}

#pragma mark - NSFetchedResultsController
- (NSFetchedResultsController*)fetchedResultsController
{
    //If we don't have the fetched controller yet, create it
    if (fetchedResultsController == nil )
    {
        //If we want to see missed calls only
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO]]];
        [request setEntity:[NSEntityDescription entityForName:@"CallRecord" inManagedObjectContext:managedObjectContext]];
        
        //Create the instance
        fetchedResultsController = [[NSFetchedResultsController alloc]
                                    initWithFetchRequest:request
                                    managedObjectContext:managedObjectContext
                                    sectionNameKeyPath:nil
                                    cacheName:nil];
        fetchedResultsController.delegate = self;
    }
    
    //Optionally set the predicate
    NSFetchRequest * fetchRequest = fetchedResultsController.fetchRequest;
    [fetchRequest setPredicate:missedCallsOnly ? missedCallsOnlyPredicate : nil];
    return fetchedResultsController;
}

- (void)performFetch
{
    NSFetchedResultsController * fetchedController = [self fetchedResultsController];
    NSError * error;
    [fetchedController performFetch:&error];
    if (error)
    {
        NBLog(@"%@", [error localizedDescription]);
    }
    else
    {
        [self reload];
    }
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self reload];
}

/*#pragma mark - DEBUG - Insert test-data into recent-called data structure
- (void)insertTestData
{
    //Cleanup
    [self clearAllRecents];
    
    //Get a copy of all contacts
    NSArray * allContacts = (__bridge NSArray *)(ABAddressBookCopyArrayOfAllPeople([[NBAddressBookManager sharedManager] getAddressBook]));
    
    //Create the instance
    ABRecordRef contactRef;
    for (int i = 0; i < 20; i++)
    {
        //Create random entries
        CallRecordData * recentContactEntry = [NSEntityDescription insertNewObjectForEntityForName:@"RecentCall" inManagedObjectContext:managedObjectContext];
        
        //Determine if this contact is known or not
        BOOL unknownContact = (arc4random()%2) == 1;
        if (!unknownContact)
        {
            //Keep iterating for a random contact with a number (some don't have a number)
            BOOL numberFound = contactRef == nil;
            while( !numberFound)
            {
                //Get a random ID from a person in the address book
                contactRef = (__bridge ABRecordRef)[allContacts objectAtIndex:(arc4random()%[allContacts count])];
                
                //Get all the numbers of this person
                ABMultiValueRef * datasource = (ABMultiValueRef*)ABRecordCopyValue(contactRef, kABPersonPhoneProperty);
                for (CFIndex i = 0; i < ABMultiValueGetCount(datasource); i++)
                {
                    //indicate we found an entry
                    NSString* number = (__bridge NSString *)(ABMultiValueCopyValueAtIndex(datasource, i));
                    number = [[NBAddressBookManager sharedManager].delegate formatNumber:number];
                    [recentContactEntry setNumber:number];
                    numberFound = YES;
                    break;
                }
            }
            
            [recentContactEntry setContactID:[NSString stringWithFormat:@"%d", ABRecordGetRecordID(contactRef)]];
        }
        else
        {
            //Set a random number
            [recentContactEntry setNumber:[NSString stringWithFormat:@"%d", (arc4random() %899999999) + 100000000]];
        }
        
        //Randomize the call status
        [recentContactEntry setStatus:[NSNumber numberWithInt:(arc4random()%4)]];
        
        //Set the date for this entry from within the last 7 days
        [recentContactEntry setDate:[self getRandomDateFromLastWeek]];
        [recentContactEntry setTimeZone:[[NSTimeZone defaultTimeZone] abbreviation]];
        
        //Randomize the direction
        [recentContactEntry setDirection:[NSNumber numberWithInt:(arc4random()%2)]];
        
        //Give it a random duration
        if ([recentContactEntry.status intValue] == CallStatusSuccess)
        {
            [recentContactEntry setDuration:@((arc4random()%60)+1)];
        }
    }
    
    [managedObjectContext save:nil];
    
    [self loadRecents:NO];
}

- (NSDate*)getRandomDateFromLastWeek
{
    //Set hours, minutes and seconds
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:( NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:[NSDate date]];
    [components setHour:arc4random()%24];
    [components setMinute:arc4random()%60];
    [components setSecond:arc4random()%60];
    
    //Subtract 0 to 7 days from this date
    NSDate * date = [cal dateFromComponents:components];
    int subtractSeconds = (60*60*24);
    int daysToSubtract = (arc4random()%7) * subtractSeconds;
    date = [NSDate dateWithTimeIntervalSinceReferenceDate:[date timeIntervalSinceReferenceDate] - daysToSubtract];
    return date;
}*/

@end
