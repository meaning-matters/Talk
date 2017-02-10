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
#import "Common.h"
#import "BadgeHandler.h"
#import "BlockAlertView.h"
#import "PhoneData.h"
#import "NumberData.h"


// These value precisly match the segment control indexes!
typedef enum
{
    CallSelectionAll      = 0,
    CallSelectionOutgoing = 1,
    CallSelectionIncoming = 2,
    CallSelectionMissed   = 3,
} CallSelection;


@interface NBRecentsListViewController ()
{
    NSManagedObjectContext*               managedObjectContext;
    NSFetchedResultsController*           fetchedResultsController;

    UISegmentedControl*                   segmentedControl;

    NBRecentUnknownContactViewController* recentUnknownViewController;
    NBRecentContactViewController*        recentViewController;

    //The missed-calls only predicate
    NSPredicate*                          incomingCallsPredicate;
    NSPredicate*                          outgoingCallsPredicate;
    NSPredicate*                          missedCallsPredicate;
    
    NSDate*                               reloadDate;

    //The recent contacts-datasource with grouping (date-sorted array with arrays (1..*) of recent entries)
    NSMutableArray*                       dataSource;

    //Flag to indicate we're displaying missed calls only
    CallSelection                         callSelection;
}

@end


@implementation NBRecentsListViewController

#pragma mark - Initialization

- (instancetype)init
{
    return [self initWithManagedObjectContext:[DataManager sharedManager].managedObjectContext];
}


- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContextParam
{
    if (self = [super init])
    {
        self.title = [Strings recentsString];
        // The tabBarItem image must be set in my own NavigationController.

        managedObjectContext = managedObjectContextParam;

        //Listen for reloads
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doLoad) name:NF_RELOAD_CONTACTS object:nil];

        [self findContactsForAnonymousItems];
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
        [self findContactsForAnonymousItems];
        [self.tableView reloadData];
    });
}


- (void)findContactsForAnonymousItems
{
    for (NSArray* recents in dataSource)
    {
        CallRecordData* recent = recents[0];
        if (recent.contactId == nil)
        {
            PhoneNumber* phoneNumber = [[PhoneNumber alloc] initWithNumber:recent.fromE164];
            [[AppDelegate appDelegate] findContactsHavingNumber:[phoneNumber nationalDigits]
                                                     completion:^(NSArray* contactIds)
            {
                recent.contactId = [contactIds firstObject];
            }];
        }
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    segmentedControl = [[UISegmentedControl alloc] initWithItems:@[NSLocalizedString(@"CNT_ALL",    @""),
                                                                   NSLocalizedString(@"CNT_OUT",    @""),
                                                                   NSLocalizedString(@"CNT_IN",     @""),
                                                                   NSLocalizedString(@"CNT_MISSED", @"")]];
    [segmentedControl setSelectedSegmentIndex:0];
    [segmentedControl setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    segmentedControl.frame = CGRectMake(0, 0, 150, 30);
    [segmentedControl addTarget:self action:@selector(segmentedControlSwitched:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = segmentedControl;

    // Set the modify-button
    editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(modifyListPressed)];
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed)];
    clearButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"CNT_CLEAR", @"")
                                                   style:UIBarButtonItemStylePlain
                                                  target:self
                                                  action:@selector(clearAction)];
    
    // The datasource
    dataSource = [NSMutableArray array];
    
    // Create the missed calls only predicate
    missedCallsPredicate   = [NSPredicate predicateWithFormat:@"(status    == %d)", CallStatusMissed];
    incomingCallsPredicate = [NSPredicate predicateWithFormat:@"(direction == %d)", CallDirectionIncoming];
    outgoingCallsPredicate = [NSPredicate predicateWithFormat:@"(direction == %d)", CallDirectionOutgoing];

    // Load in the initial content
    [self performFetchWithForce:NO];
    
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
    
    [self reloadForce:NO];

    //### Workaround: http://stackoverflow.com/a/19126113/1971013
    //### And it also fixes my own issue: http://stackoverflow.com/a/22626388/1971013
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [self.refreshControl beginRefreshing];
        [self.refreshControl endRefreshing];
    });
}


- (void)viewWillDisappear:(BOOL)animated
{
    [[BadgeHandler sharedHandler] setBadgeCount:0 forViewController:self];
}


- (void)refresh:(id)sender
{
    [self retrieveCallRecordsWithSender:sender completion:nil];
}


- (void)retrieveCallRecordsWithSender:(id)sender completion:(void(^)(NSError* error))completion
{
    NSDate* date = [Settings sharedSettings].recentsCheckDate;

    //####### TEMP
    //date = [[NSDate date] dateByAddingTimeInterval:-100000];

    [[WebClient sharedClient] retrieveCallRecordsFromDate:date
                                                  inbound:YES
                                                 outbound:NO
                                             verification:NO
                                                    reply:^(NSError *error, NSArray* records)
    {
        if (error == nil)
        {
            [Settings sharedSettings].recentsCheckDate = [NSDate date];

            [self processCallRecords:records];

            [sender endRefreshing];
        }
        else if (sender != nil)
        {
            NSString* message = NSLocalizedString(@"Checking for new incoming calls failed: %@", @"");
            [BlockAlertView showAlertViewWithTitle:NSLocalizedString(@"Check Failed", @"")
                                           message:[NSString stringWithFormat:message, [error localizedDescription]]
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
            {
                [sender endRefreshing];
            }
                                 cancelButtonTitle:[Strings closeString]
                                 otherButtonTitles:nil];
        }

        completion ? completion(error) : 0;
    }];
}


/**
 A call record represent one leg of a call and has the following fields:
     - billable_duration: From this and the `cost` the rate per minute can be calculated. This is "<null>" for cancelled
                          calls.

     - cost:              The costs in the user's currency (that's supplied with the API call).

     - duration:          Time this leg was active.

     - fromE164           E164 of the originating party (caller)
 
     - toE164             E164 of the destinating party (callee)
 
     - hangupCause       Condition by which this leg was ended, one of (in order of frequency; a occurrence count
                          from OCT 2016 is added):
                              NORMAL_CLEARING        12851
                              <null>                  2268 // Probably old NumberBay system.
                              ORIGINATOR_CANCEL       1395
                              USER_BUSY                458
                              UNALLOCATED_NUMBER       356
                              NO_USER_RESPONSE         287
                              CALL_REJECTED            138
                              NORMAL_UNSPECIFIED       132
                              NORMAL_TEMPORARY_FAILURE 116
                              INVALID_NUMBER_FORMAT    113
                              RECOVERY_ON_TIMER_EXPIRE  97
                              NONE                      54
                              ALLOTTED_TIMEOUT          44
                              NO_ROUTE_DESTINATION      40
                              NO_ANSWER                 38
                              UNKNOWN                   34
                              DESTINATION_OUT_OF_ORDER  23
                              INCOMPATIBLE_DESTINATION  15
                              MANDATORY_IE_MISSING      13
                              NETWORK_OUT_OF_ORDER      12
                              MEDIA_TIMEOUT             12
                              INTERWORKING               6
                              EXCHANGE_ROUTING_ERROR     6
                              SERVICE_UNAVAILABLE        5
                              SERVICE_NOT_IMPLEMENTED    5
                              LOSE_RACE                  5
                              NORMAL_CIRCUIT_CONGESTION  3

    - startDateTime:      The start date & time in GMT.

    - type:               Indication of the type of leg. Possible values (in order of frequency; a occurrence count from
                          OCT 2016 is added) are:
                              <null>     16615  // Old NumberBay system and early stages of new system.
                              callback     564  // From-leg of a callback/outgoing call.
                              inbound      446  // From-leg of an incoming call (originating externally).
                              callthru     399  // To-leg of a callback/outgoing call.
                              ivr          269  // To-leg of an incoming call (towards a Phone).
                              verification 108  // Phone verification To call.
                              subscriber    68  // ??
                              outbound      57  // To-leg of incoming call, but towards a SIP phone.
                              textback       6  // SMS call.

     - uuid:              The UUID of this call.
 
 The records are ordered by creation date, with the newest records on top (i.e. at lower indices). Matching legs (having
 the same UUID) can normally be found next to eachother. Only on a busy system where multiple calls are initiated around
 the same time, both legs can be a little further apart.
 
               Leg Type                         fromE164                     toE164
    --------------------------------------------------------------+-----------------------------
         (A) fromRecord "inbound"         originator Caller ID or |  Voxbone Number that caller
                                          "anonymous"             |  dialed
    INCOMING                                                      |
                                                                  |
         (B) toRecord "ivr" or "outbound" ON:  Voxbone Number     |  Phone call is forwarded to
          Depends on "Show Called Number" OFF: Caller             |
    --------------------------------------------------------------+-----------------------------
         (A) fromRecord "callback"        NumberBay Ltd. main     |  Phone where callback is
                                          Number, always          |  received.
    OUTGOING                                                      |
                                                                  |
         (B) toRecord "callthru"          Chosen Caller ID        |  Callee, the person that's
                                                                  |  being called.
     -------------------------------------------------------------+-----------------------------
 */
- (void)processCallRecords:(NSArray*)records
{
    NSString* uuid;

    for (int index = (int)(records.count - 1); index >= 0; index--)
    {
        NSDictionary* record = records[index];

        // Skip the calls that we already have.
        uuid = record[@"uuid"];
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"uuid == %@", uuid];
        if ([[DataManager sharedManager] fetchEntitiesWithName:@"CallRecord"
                                                  sortKeys:nil
                                                 predicate:predicate
                                      managedObjectContext:nil].count != 0)
        {
            continue;
        }

        // We're expecting 'callback', 'inbound' or 'verification'.
        if ([self isCallbackRecord:record] || [self isInboundRecord:record] || [self isVerificationRecord:record])
        {
            if ([self isVerificationRecord:record])
            {
                [self addVerificationRecord:record];
            }
            else
            {
                NSInteger secondIndex = [self secondCallRecordIndexWithFirst:index callRecords:records];
                if (secondIndex != NSNotFound)
                {
                    [self addRecentWithFromRecord:record toRecord:records[secondIndex]];

                    // If records are adjacent.
                    if ((index - secondIndex) == 1)
                    {
                        index--;
                    }
                }
                else
                {
                    [self addRecentWithFromRecord:record];
                }
            }
        }
        else
        {
            // Discard this record. Could be index 0 record (in which case we just missed loading the first leg
            // record), or a second leg (non-adjacent to its first) we found earlier (when on a busy system with
            // many calls).
            NBLog(@"Discarding CDR leg record.");
        }
    }
}


- (NSInteger)secondCallRecordIndexWithFirst:(NSInteger)firstIndex callRecords:(NSArray*)records
{
    NSDictionary* firstRecord = records[firstIndex];

    for (NSInteger secondIndex = (firstIndex - 1); secondIndex >= 0; secondIndex--)
    {
        NSDictionary* secondRecord = records[secondIndex];

        if ([firstRecord[@"uuid"] isEqualToString:secondRecord[@"uuid"]])
        {
            return secondIndex;
        }
    }

    return NSNotFound;
}


- (BOOL)isCallbackRecord:(NSDictionary*)record
{
    return [record[@"type"] isEqualToString:@"callback"];
}


- (BOOL)isInboundRecord:(NSDictionary*)record
{
    return [record[@"type"] isEqualToString:@"inbound"];
}


- (BOOL)isCallthruRecord:(NSDictionary*)record
{
    return [record[@"type"] isEqualToString:@"callthru"];
}


- (BOOL)isIvrRecord:(NSDictionary*)record
{
    return [record[@"type"] isEqualToString:@"ivr"];
}


- (BOOL)isVerificationRecord:(NSDictionary*)record
{
    return [record[@"type"] isEqualToString:@"verification"];
}


- (void)addRecentWithFromRecord:(NSDictionary*)fromRecord
{
    NSManagedObjectContext* context = [DataManager sharedManager].managedObjectContext;
    CallRecordData*         recent  = [NSEntityDescription insertNewObjectForEntityForName:@"CallRecord"
                                                                    inManagedObjectContext:context];
    recent.isUpToDate = @(YES);

    PhoneNumber* contactPhoneNumber;
    if ([self isCallbackRecord:fromRecord])
    {
        // Cancelled outbound call (callback).
        recent.direction    = @(CallDirectionOutgoing);
        contactPhoneNumber  = [[PhoneNumber alloc] initWithNumber:[self addE164Plus:fromRecord[@"toE164"]]]; // The NB number, the called number is lost.
        recent.date         = [Common dateWithString:fromRecord[@"startDateTime"]]; // When we started calling.
        recent.callerIdE164 = nil;

        recent.fromE164     = [self addE164Plus:fromRecord[@"fromE164"]];
        recent.toE164       = [self addE164Plus:fromRecord[@"toE164"]];
        recent.fromCost     = fromRecord[@"cost"];
        recent.toCost       = @(0.0);

        if ([fromRecord[@"hangupCause"] isEqualToString:@"NORMAL_CLEARING"])
        {
            // When an inbound caller hangs up before and outbound leg was created, we want to show this
            // as a missed called, otherwise it's a regular cancelled call.
            recent.status = [self isInboundRecord:fromRecord] ? @(CallStatusMissed) : @(CallStatusCancelled);
        }
        else
        {
            //#### TODO: Elaborate with actual status string values.
            recent.status = @(CallStatusFailed);
        }
    }
    else if ([self isInboundRecord:fromRecord])
    {
        recent.direction    = @(CallDirectionIncoming);
        contactPhoneNumber  = [[PhoneNumber alloc] initWithNumber:[self addE164Plus:fromRecord[@"fromE164"]]];
        recent.date         = [Common dateWithString:fromRecord[@"startDateTime"]]; // When we started calling.
        recent.callerIdE164 = [self addE164Plus:fromRecord[@"fromE164"]];

        recent.fromE164     = [self addE164Plus:fromRecord[@"fromE164"]];
        recent.toE164       = [self addE164Plus:fromRecord[@"toE164"]];
        recent.fromCost     = fromRecord[@"cost"];
        recent.toCost       = @(0.0);

        if ([fromRecord[@"hangupCause"] isEqualToString:@"NORMAL_CLEARING"])
        {
            recent.status = @(CallStatusCancelled);
        }
        else
        {
            //#### TODO: Elaborate with actual status string values.
            recent.status = @(CallStatusFailed);
        }
    }
    else
    {
        NBLog(@"Unexpected CDR leg record: %@", fromRecord[@"type"]);
    }

    recent.timeZone             = [[NSTimeZone defaultTimeZone] abbreviation];
    recent.uuid                 = fromRecord[@"uuid"];

    recent.fromDuration         = fromRecord[@"duration"];
    recent.toDuration           = @(0);
    recent.billableFromDuration = fromRecord[@"billableDuration"];
    recent.billableToDuration   = @(0.0);

    recent.dialedNumber = [contactPhoneNumber internationalFormat];
    [[AppDelegate appDelegate] findContactsHavingNumber:[contactPhoneNumber nationalDigits]
                                             completion:^(NSArray* contactIds)
    {
        if (contactIds.count > 0)
        {
            recent.contactId = [contactIds firstObject];

            [self reloadForce:YES];
        }
    }];
}


- (void)addRecentWithFromRecord:(NSDictionary*)fromRecord toRecord:(NSDictionary*)toRecord
{
    NSManagedObjectContext* context = [DataManager sharedManager].managedObjectContext;
    CallRecordData*         recent  = [NSEntityDescription insertNewObjectForEntityForName:@"CallRecord"
                                                                    inManagedObjectContext:context];

    /*
     INBOUND FROM:
     billableDuration = 0;
     cost = 0;
     duration = 38;
     fromE164 = 443301223030;
     hangupCause = "NORMAL_CLEARING";
     startDateTime = "2016-11-09 14:28:19";
     toE164 = 442038083855;
     type = inbound;
     uuid = "c2a35c12-a688-11e6-982d-1b853daeb411";

     INBOUND TO:
     billableDuration = 0;
     cost = 0;
     duration = 38;
     fromE164 = 442038083855;
     hangupCause = "NO_USER_RESPONSE";
     startDateTime = "2016-11-09 14:28:19";
     toE164 = 34630535344;
     type = ivr;
     uuid = "c2a35c12-a688-11e6-982d-1b853daeb411";
     
     ==========

     OUTBOUND FROM:
     billableDuration = 17;
     cost = "0.02235067964002524";
     duration = 27;
     fromE164 = 442038083855;
     hangupCause = "NORMAL_CLEARING";
     startDateTime = "2016-11-14 16:36:35";
     toE164 = 34630535344;
     type = callback;
     uuid = "81bb6c72-aa88-11e6-bb44-8ddf088a4149";

     OUTBOUND TO:
     billableDuration = 5;
     cost = "0.001861347425062485";
     duration = 13;
     fromE164 = 34630535344;
     hangupCause = "NORMAL_CLEARING";
     startDateTime = "2016-11-14 16:36:48";
     toE164 = 3215666666;
     type = callthru;
     uuid = "81bb6c72-aa88-11e6-bb44-8ddf088a4149";
     
     ===========
     
     VERIFICATION OK:
     billableDuration = 9;
     cost = "0.0107125248668";
     duration = 15;
     fromE164 = 442038083855;
     hangupCause = "NORMAL_CLEARING";
     startDateTime = "2017-01-21 09:05:41";
     toE164 = 34630535344;
     type = verification;
     uuid = "c8a33c72-dfb8-11e6-83b2-2bb2e8aa3c64";

     VERIFICATION CANCELLED:
     billableDuration = 0;
     cost = 0;
     duration = 19;
     fromE164 = 442038083855;
     hangupCause = "NO_USER_RESPONSE";
     startDateTime = "2017-01-21 09:04:01";
     toE164 = 34630535344;
     type = verification;
     uuid = "8ce8aa00-dfb8-11e6-95e4-add0451aea3e";
     */

    PhoneNumber* contactPhoneNumber;
    if ([self isCallbackRecord:fromRecord])
    {
        //##### OUTDATED AS WE DON'T LOAD OUTGOING CALLS YET.
        // Outbound call (callback).
        recent.direction    = @(CallDirectionOutgoing);
        contactPhoneNumber  = [[PhoneNumber alloc] initWithNumber:[self addE164Plus:toRecord[@"toE164"]]];
        recent.date         = [Common dateWithString:fromRecord[@"startDateTime"]]; // When we started calling.
        recent.callerIdE164 = [self addE164Plus:toRecord[@"fromE164"]];

        recent.fromE164     = [self addE164Plus:fromRecord[@"toE164"]];
        recent.toE164       = [self addE164Plus:toRecord[@"toE164"]];
        recent.fromCost     = fromRecord[@"cost"];
        recent.toCost       = toRecord[@"cost"];

        if ([toRecord[@"hangupCause"] isEqualToString:@"NORMAL_CLEARING"])
        {
            recent.status = @(CallStatusSuccess);
        }
        else
        {
            //#### TODO: Elaborate with actual status string values.
            recent.status = @(CallStatusFailed);

            [[BadgeHandler sharedHandler] badgeCountForViewController:self];
        }
    }
    else
    {
        // Inbound call (Voxbone).
        recent.direction    = @(CallDirectionIncoming);
        contactPhoneNumber  = [[PhoneNumber alloc] initWithNumber:[self addE164Plus:fromRecord[@"fromE164"]]];
        recent.date         = [Common dateWithString:toRecord[@"startDateTime"]];   // When our Phone was called.
        recent.callerIdE164 = [self addE164Plus:fromRecord[@"fromE164"]];

        recent.fromE164     = [self addE164Plus:fromRecord[@"fromE164"]];  // Depends on Setting: either NumberBay main number, or caller number.
        recent.toE164       = [self addE164Plus:fromRecord[@"toE164"]];
        recent.fromCost     = fromRecord[@"cost"];
        recent.toCost       = toRecord[@"cost"];

        if ([toRecord[@"hangupCause"] isEqualToString:@"NORMAL_CLEARING"])
        {
            recent.status = @(CallStatusSuccess);
        }
        else
        {
            //#### TODO: Elaborate with actual status string values.
            recent.status = @(CallStatusMissed);

            NSUInteger badgeCount = [[BadgeHandler sharedHandler] badgeCountForViewController:self];
            [[BadgeHandler sharedHandler] setBadgeCount:(badgeCount + 1) forViewController:self];
        }
    }

    recent.timeZone             = [[NSTimeZone defaultTimeZone] abbreviation];
    recent.uuid                 = fromRecord[@"uuid"];

    recent.fromDuration         = fromRecord[@"duration"];
    recent.toDuration           = toRecord[@"duration"];
    recent.billableFromDuration = fromRecord[@"billableDuration"];
    recent.billableToDuration   = toRecord[@"billableDuration"];

    recent.dialedNumber = [contactPhoneNumber internationalFormat];
    [[AppDelegate appDelegate] findContactsHavingNumber:[contactPhoneNumber nationalDigits]
                                             completion:^(NSArray* contactIds)
    {
        if (contactIds.count > 0)
        {
            recent.contactId = [contactIds firstObject];

            [self reloadForce:YES];
        }
    }];
}


/*
 VERIFICATION OK:
 billableDuration = 9;
 cost = "0.0107125248668";
 duration = 15;
 fromE164 = 442038083855;
 hangupCause = "NORMAL_CLEARING";
 startDateTime = "2017-01-21 09:05:41";
 toE164 = 34630535344;
 type = verification;
 uuid = "c8a33c72-dfb8-11e6-83b2-2bb2e8aa3c64";

 VERIFICATION CANCELLED:
 billableDuration = 0;
 cost = 0;
 duration = 19;
 fromE164 = 442038083855;
 hangupCause = "NO_USER_RESPONSE";
 startDateTime = "2017-01-21 09:04:01";
 toE164 = 34630535344;
 type = verification;
 uuid = "8ce8aa00-dfb8-11e6-95e4-add0451aea3e";
 */
- (void)addVerificationRecord:(NSDictionary*)record
{
    NSManagedObjectContext* context            = [DataManager sharedManager].managedObjectContext;
    CallRecordData*         recent             = [NSEntityDescription insertNewObjectForEntityForName:@"CallRecord"
                                                                               inManagedObjectContext:context];
    PhoneNumber*            contactPhoneNumber = [[PhoneNumber alloc] initWithNumber:[self addE164Plus:record[@"fromE164"]]];

    recent.isUpToDate           = @(YES);

    recent.direction            = @(CallDirectionVerification);
    recent.date                 = [Common dateWithString:record[@"startDateTime"]]; // When we started calling.

    recent.fromE164             = [self addE164Plus:record[@"fromE164"]];
    recent.toE164               = [self addE164Plus:record[@"toE164"]];
    recent.fromCost             = record[@"cost"];
    recent.toCost               = @(0.0);

    recent.timeZone             = [[NSTimeZone defaultTimeZone] abbreviation];
    recent.uuid                 = record[@"uuid"];

    recent.fromDuration         = record[@"duration"];
    recent.toDuration           = @(0);
    recent.billableFromDuration = record[@"billableDuration"];
    recent.billableToDuration   = @(0.0);

    recent.dialedNumber = @"+442035083588";

    if ([record[@"hangupCause"] isEqualToString:@"NORMAL_CLEARING"])
    {
        recent.status = @(CallStatusSuccess);
    }
    else if ([record[@"hangupCause"] isEqualToString:@"ORIGINATOR_CANCEL"])
    {
        recent.status = @(CallStatusCancelled);
    }
    else if ([record[@"hangupCause"] isEqualToString:@"USER_BUSY"])
    {
        recent.status = @(CallStatusBusy);
    }
    else if ([record[@"hangupCause"] isEqualToString:@"NO_USER_RESPONSE"])
    {
        recent.status = @(CallStatusMissed);
    }
    else if ([record[@"hangupCause"] isEqualToString:@"CALL_REJECTED"])
    {
        recent.status = @(CallStatusDeclined);
    }
    else
    {
        recent.status = @(CallStatusFailed);
    }

    recent.dialedNumber = [contactPhoneNumber internationalFormat];
    [[AppDelegate appDelegate] findContactsHavingNumber:[contactPhoneNumber nationalDigits]
                                             completion:^(NSArray* contactIds)
    {
        if (contactIds.count > 0)
        {
            recent.contactId = [contactIds firstObject];

            [self reloadForce:YES];
        }
    }];
}


- (NSString*)addE164Plus:(NSString*)e164WithoutPlus
{
    if (e164WithoutPlus.length == 0 || [e164WithoutPlus isEqualToString:@"anonymous"])
    {
        return nil;
    }
    else
    {
        return [@"+" stringByAppendingString:e164WithoutPlus];
    }
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

- (void)clearAction
{
    UIActionSheet* clearActionSheet;
    NSString*      title;

    switch ((CallSelection)segmentedControl.selectedSegmentIndex)
    {
        case CallSelectionAll:      title = NSLocalizedString(@"CNT_CLEAR_ALL_TITLE",    @""); break;
        case CallSelectionOutgoing: title = NSLocalizedString(@"CNT_CLEAR_OUT_TITLE",    @""); break;
        case CallSelectionIncoming: title = NSLocalizedString(@"CNT_CLEAR_IN_TITLE",     @""); break;
        case CallSelectionMissed:   title = NSLocalizedString(@"CNT_CLEAR_MISSED_TITLE", @""); break;
    }

    clearActionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"NCT_CANCEL", @"")
                                     destructiveButtonTitle:nil
                                          otherButtonTitles:NSLocalizedString(@"CNT_CLEAR_WEEK", @""),
                        NSLocalizedString(@"CNT_CLEAR_MONTH", @""),
                        NSLocalizedString(@"CNT_CLEAR_ALL",   @""), nil];

    [clearActionSheet showFromTabBar:[[self.navigationController tabBarController] tabBar]];
}


- (void)clearOneWeekRecents
{
    NSCalendar*       calendar    = [NSCalendar currentCalendar];
    NSDateComponents* components  = [NSDateComponents new];
    components.weekOfYear         = -1; // This also works for first week of the year.
    NSDate*           weekAgoDate = [calendar dateByAddingComponents:components toDate:[NSDate date] options:0];

    // Clear all the old objects
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
            [self reloadForce:NO];
            break;
        }
        case 1:
        {
            [self clearOneMonthRecents];
            [self reloadForce:NO];
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
    [self reloadForce:NO];
}


- (void)reloadForce:(BOOL)force
{
    // Only perform a full reload if more calls were made or when it's the next day.
    NSCalendar* calendar          = [NSCalendar currentCalendar];
    NSArray*    allRecentContacts = [self.fetchedResultsController fetchedObjects];
    
    if (force || numRecentCalls == 0 || [allRecentContacts count] != numRecentCalls ||
        ![calendar isDate:[NSDate date] inSameDayAsDate:reloadDate])
    {
        reloadDate = [NSDate date];
        
        // Performance improvement
        numRecentCalls = (int)[allRecentContacts count];
        
        // Group the recent contacts into a datasource
        [dataSource removeAllObjects];
        CallRecordData* lastEntry;
        NSMutableArray* entryArray;
        for (CallRecordData* entry in allRecentContacts)
        {
            // If we don't have a last entry or it doesn't match the record or number, create a new entry
            BOOL entryAdded = NO;
            if (lastEntry != nil)
            {
                // If we have the same contact,
                // the same unknown number,
                // or are a missed call same as the last entry
                if (( [lastEntry.contactId isEqualToString:entry.contactId] ||
                    ( lastEntry.contactId == nil && entry.contactId == nil && [lastEntry.dialedNumber isEqualToString:entry.dialedNumber])) &&
                    ( ( [lastEntry.status intValue] == CallStatusMissed && [entry.status intValue] == CallStatusMissed) ||
                    ( [lastEntry.status intValue] != CallStatusMissed && [entry.status intValue] != CallStatusMissed)))
                {
                    // If the last entry's day is equal to this day
                    if ([calendar isDate:lastEntry.date inSameDayAsDate:entry.date])
                    {
                        [entryArray addObject:entry];
                        entryAdded = YES;
                    }
                }
            }
            
            // If we haven't added the entry to the last group, add it now
            if (!entryAdded)
            {
                entryArray = [NSMutableArray array];
                [entryArray addObject:entry];   
                [dataSource addObject:entryArray];
            }
            
            //Remember for the next check
            lastEntry = entry;
        }

        if (!self.tableView.editing)
        {
            if ([allRecentContacts count] > 0)
            {
                [self.navigationItem setRightBarButtonItem:editButton];
            }
            else
            {
                [self.navigationItem setRightBarButtonItem:nil];
            }
        }
        
        // Animate in/out the rows
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}


#pragma mark - Segmented control change

- (void)segmentedControlSwitched:(UISegmentedControl*)control
{
    // End editing
    [self donePressed];
    
    callSelection = (CallSelection)control.selectedSegmentIndex;

    [self performFetchWithForce:YES];
}


#pragma mark - Modifying the table

- (void)modifyListPressed
{
    //Shift all the labels in view
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:ANIMATION_SPEED];
    NSArray* visiblePaths = [self.tableView indexPathsForVisibleRows];
    for (NSIndexPath *indexPath in visiblePaths)
    {
        NBRecentCallCell* missedCallCell = (NBRecentCallCell *)[self.tableView cellForRowAtIndexPath:indexPath];
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
        cell = [[NBRecentCallCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleDefault];
        
        //Add a number label
        UILabel* numberLabel = [[UILabel alloc] initWithFrame:CGRectMake(POSITION_NUMBER_LABEL,
                                                                         7,
                                                                         SIZE_NUMBER_LABEL,
                                                                         20)];
        [numberLabel setBackgroundColor:[UIColor clearColor]];
        [numberLabel setFont:[UIFont boldSystemFontOfSize:16]];
        [cell setNumberLabel:numberLabel];
        [cell addSubview:numberLabel];

        // Add a number type label
        UILabel* typeLabel = [[UILabel alloc] initWithFrame:CGRectMake(POSITION_NUMBER_LABEL,
                                                                      25,
                                                                      SIZE_NUMBER_LABEL,
                                                                      20)];
        [typeLabel setBackgroundColor:[UIColor clearColor]];
        [typeLabel setFont:[UIFont systemFontOfSize:13]];
        cell.numberTypeLabel= typeLabel;
        [cell addSubview:typeLabel];

        // Add Caller ID label
        UILabel* idLabel = [[UILabel alloc] initWithFrame:CGRectMake(POSITION_NUMBER_LABEL,
                                                                     43,
                                                                     SIZE_NUMBER_LABEL,
                                                                     20)];
        [idLabel setBackgroundColor:[UIColor clearColor]];
        [idLabel setFont:[UIFont systemFontOfSize:13]];
        [idLabel setTextColor:[[NBAddressBookManager sharedManager].delegate valueColor]];
        cell.callerIdLabel= idLabel;
        [cell addSubview:idLabel];
    }

    // Set the number and description
    CallRecordData* latestEntry = [entryRowArray objectAtIndex:0];
    ABRecordRef     contact;
    if (latestEntry.contactId != nil)
    {
        contact = [self getContactForID:latestEntry.contactId];
        if (contact == nil)
        {
            // Contact appears to be gone, clear it.
            for (CallRecordData* entry in entryRowArray)
            {
                entry.contactId = nil;
            }
        }
    }

    switch ([latestEntry.direction intValue])
    {
        case CallDirectionIncoming:     [self configureInboundCell:cell      callRecord:latestEntry]; break;
        case CallDirectionOutgoing:     [self configureOutboundCell:cell     callRecord:latestEntry]; break;
        case CallDirectionVerification: [self configureVerificationCell:cell callRecord:latestEntry]; break;
    }

    // Set the amount of calls made (incoming + outgoing)
    if ([entryRowArray count] > 1)
    {
        //Set the last part as greyed out regular
        NSMutableAttributedString* attributedName;
        attributedName = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ (%lu)",
                                                                            cell.numberLabel.text,
                                                                            (unsigned long)[entryRowArray count]]
                                                                attributes:[NSDictionary dictionaryWithObjectsAndKeys:cell.numberLabel.font,
                                                                            NSFontAttributeName, nil]];

        [attributedName setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                       [UIFont systemFontOfSize:16],
                                       NSFontAttributeName,
                                       [UIColor grayColor],
                                       NSForegroundColorAttributeName,nil]
                                range:NSMakeRange([cell.numberLabel.text length], [attributedName length] - [cell.numberLabel.text length])];
        [cell.numberLabel setAttributedText:attributedName];
    }

    cell.imageView.image = [cell.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    if ([latestEntry.status intValue] == CallStatusMissed)
    {
        [cell.imageView setTintColor:[[NBAddressBookManager sharedManager].delegate deleteTintColor]];
    }
    else
    {
        [cell.imageView setTintColor:[[NBAddressBookManager sharedManager].delegate valueColor]];
    }

    // Set the time and (yesterday/day name in case of less than a week ago/date)
    NSString*         dayOrDate;
    NSCalendar*       cal         = [NSCalendar currentCalendar];
    NSDateComponents* components  = [cal components:(NSCalendarUnitYear       | NSCalendarUnitMonth |
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
    [cell.detailTextLabel setTextColor:[[NBAddressBookManager sharedManager].delegate valueColor]];
    [cell setAccessoryType:UITableViewCellAccessoryDetailButton];
    
    return cell;
}


- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)aCell forRowAtIndexPath:(NSIndexPath*)indexPath
{        
    // Set the approriate cell spacing and frame for the labels
    NBRecentCallCell* cell = (NBRecentCallCell*)aCell;
    [cell shiftLabels:self.navigationItem.rightBarButtonItem == doneButton];
}


- (void)configureInboundCell:(NBRecentCallCell*)cell callRecord:(CallRecordData*)callRecord
{
    if (callRecord.contactId != nil)
    {
        ABRecordRef contact = [self getContactForID:callRecord.contactId];

        // Set the name
        NSString* representation = [[NBContact getListRepresentation:contact] string];
        [cell.numberLabel setText:representation];

        cell.numberTypeLabel.text = nil;

        // Determine and set the label
        ABMultiValueRef* datasource = (ABMultiValueRef*)ABRecordCopyValue(contact, kABPersonPhoneProperty);
        for (CFIndex i = 0; i < ABMultiValueGetCount(datasource); i++)
        {
            NSString* number = (__bridge NSString*)(ABMultiValueCopyValueAtIndex(datasource, i));

            if ([[NBAddressBookManager sharedManager].delegate matchRecent:callRecord withNumber:number])
            {
                [cell.numberTypeLabel setText:(__bridge NSString*)ABAddressBookCopyLocalizedLabel((ABMultiValueCopyLabelAtIndex(datasource, i)))];

                break;
            }
        }
    }
    else if (callRecord.dialedNumber == nil)
    {
        [cell.numberLabel     setText:NSLocalizedString(@"LBL_NO_CALLER_ID", @"")];
        [cell.numberTypeLabel setText:NSLocalizedString(@"LBL_UNKNOWN", @"")];
    }
    else
    {
        NSString* number = [[NBAddressBookManager sharedManager].delegate formatNumber:callRecord.dialedNumber];
        [cell.numberLabel     setText:number];
        [cell.numberTypeLabel setText:NSLocalizedString(@"LBL_UNKNOWN", @"")];
    }

    if ([callRecord.status intValue] == CallStatusMissed)
    {
        cell.numberLabel.textColor     = [[NBAddressBookManager sharedManager].delegate deleteTintColor];
        cell.numberTypeLabel.textColor = [[NBAddressBookManager sharedManager].delegate deleteTintColor];
    }
    else
    {
        cell.numberLabel.textColor     = [UIColor blackColor];
        cell.numberTypeLabel.textColor = [UIColor blackColor];
    }

    // Set the Caller ID.
    NumberData* number = [[DataManager sharedManager] lookupNumberForE164:callRecord.toE164];

    if (number != nil)
    {
        cell.callerIdLabel.text = number.name;
    }
    else
    {
        // Strange situation because a Number was called that's not there.
        cell.callerIdLabel.text = [[[PhoneNumber alloc] initWithNumber:callRecord.toE164] internationalFormat];
    }

    cell.imageView.image = [UIImage imageNamed:@"CallIncoming"];
}


- (void)configureOutboundCell:(NBRecentCallCell*)cell callRecord:(CallRecordData*)callRecord
{
    if (callRecord.contactId != nil)
    {
        ABRecordRef contact = [self getContactForID:callRecord.contactId];

        // Set the name
        NSString* representation = [[NBContact getListRepresentation:contact] string];
        [cell.numberLabel setText:representation];

        cell.numberTypeLabel.text = nil;

        // Determine and set the label
        ABMultiValueRef* datasource = (ABMultiValueRef*)ABRecordCopyValue(contact, kABPersonPhoneProperty);
        for (CFIndex i = 0; i < ABMultiValueGetCount(datasource); i++)
        {
            NSString* number = (__bridge NSString*)(ABMultiValueCopyValueAtIndex(datasource, i));

            if ([[NBAddressBookManager sharedManager].delegate matchRecent:callRecord withNumber:number])
            {
                [cell.numberTypeLabel setText:(__bridge NSString*)ABAddressBookCopyLocalizedLabel((ABMultiValueCopyLabelAtIndex(datasource, i)))];

                break;
            }
        }
    }
    else if (callRecord.dialedNumber == nil)
    {
        [cell.numberLabel     setText:NSLocalizedString(@"LBL_NO_CALLER_ID", @"")];
        [cell.numberTypeLabel setText:NSLocalizedString(@"LBL_UNKNOWN", @"")];
    }
    else
    {
        NSString* number = [[NBAddressBookManager sharedManager].delegate formatNumber:callRecord.dialedNumber];
        [cell.numberLabel     setText:number];
        [cell.numberTypeLabel setText:NSLocalizedString(@"LBL_UNKNOWN", @"")];
    }

    if ([callRecord.status intValue] == CallStatusMissed)
    {
        cell.numberLabel.textColor     = [[NBAddressBookManager sharedManager].delegate deleteTintColor];
        cell.numberTypeLabel.textColor = [[NBAddressBookManager sharedManager].delegate deleteTintColor];
    }
    else
    {
        cell.numberLabel.textColor     = [UIColor blackColor];
        cell.numberTypeLabel.textColor = [UIColor blackColor];
    }

    // Set the Caller ID.
    if ([callRecord.privacy boolValue])
    {
        cell.callerIdLabel.text = @"anonymous";
    }
    else
    {
        PhoneData*  phone  = [[DataManager sharedManager] lookupPhoneForE164:callRecord.callerIdE164];
        NumberData* number = [[DataManager sharedManager] lookupNumberForE164:callRecord.callerIdE164];

        if (phone != nil)
        {
            cell.callerIdLabel.text = phone.name;
        }
        else if (number != nil)
        {
            cell.callerIdLabel.text = number.name;
        }
        else
        {
            // Strange situation because a Caller ID was used that's no longer there.
            cell.callerIdLabel.text = [[[PhoneNumber alloc] initWithNumber:callRecord.callerIdE164] internationalFormat];
        }
    }

    cell.imageView.image = [UIImage imageNamed:@"CallOutgoing"];
}


- (void)configureVerificationCell:(NBRecentCallCell*)cell callRecord:(CallRecordData*)callRecord
{
    if (callRecord.contactId != nil)
    {
        ABRecordRef contact = [self getContactForID:callRecord.contactId];

        // Set the name
        NSString* representation = [[NBContact getListRepresentation:contact] string];
        [cell.numberLabel setText:representation];

        cell.numberTypeLabel.text = nil;

        // Determine and set the label
        ABMultiValueRef* datasource = (ABMultiValueRef*)ABRecordCopyValue(contact, kABPersonPhoneProperty);
        for (CFIndex i = 0; i < ABMultiValueGetCount(datasource); i++)
        {
            NSString* number = (__bridge NSString*)(ABMultiValueCopyValueAtIndex(datasource, i));

            if ([[NBAddressBookManager sharedManager].delegate matchRecent:callRecord withNumber:number])
            {
                [cell.numberTypeLabel setText:(__bridge NSString*)ABAddressBookCopyLocalizedLabel((ABMultiValueCopyLabelAtIndex(datasource, i)))];

                break;
            }
        }
    }
    else
    {
        NSString* number = [[NBAddressBookManager sharedManager].delegate formatNumber:callRecord.dialedNumber];
        [cell.numberLabel     setText:number];
        [cell.numberTypeLabel setText:@"verification"];
    }

    if ([callRecord.status intValue] == CallStatusMissed)
    {
        cell.numberLabel.textColor     = [[NBAddressBookManager sharedManager].delegate deleteTintColor];
        cell.numberTypeLabel.textColor = [[NBAddressBookManager sharedManager].delegate deleteTintColor];
    }
    else
    {
        cell.numberLabel.textColor     = [UIColor blackColor];
        cell.numberTypeLabel.textColor = [UIColor blackColor];
    }

    // Set the Caller ID.
    PhoneData* phone = [[DataManager sharedManager] lookupPhoneForE164:callRecord.toE164];
    if (phone != nil)
    {
        cell.callerIdLabel.text = phone.name;
    }
    else
    {
        cell.callerIdLabel.text = [[[PhoneNumber alloc] initWithNumber:callRecord.toE164] internationalFormat];
    }

    cell.imageView.image = [UIImage imageNamed:@"CallVerification"];
}


// Override to support editing the table view.

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        // Remove the row form the local model
        NSArray* entryArray  = [dataSource objectAtIndex:indexPath.row];
        [dataSource removeObject:entryArray];
        
        // Remove the object from coredata
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

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return 69;
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSArray*        recents     = [dataSource objectAtIndex:indexPath.row];
    CallRecordData* firstRecent = [recents objectAtIndex:0];

    switch ([firstRecent.direction intValue])
    {
        case CallDirectionIncoming:
        {
            [NBContact makePhoneCall:firstRecent.dialedNumber withContactID:firstRecent.contactId callerId:firstRecent.toE164];

            break;
        }
        case CallDirectionOutgoing:
        {
            [NBContact makePhoneCall:firstRecent.dialedNumber withContactID:firstRecent.contactId callerId:firstRecent.callerIdE164];

            break;
        }
        case CallDirectionVerification:
        {
            // Ignore.
            break;
        }
    }

    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];    
}


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    NSArray*        recents     = [dataSource objectAtIndex:indexPath.row];
    CallRecordData* firstRecent = [recents objectAtIndex:0];
    if (firstRecent.contactId == nil)
    {
        // Load as unknown person
        recentUnknownViewController = [[NBRecentUnknownContactViewController alloc] init];
        [recentUnknownViewController setAddUnknownContactDelegate:self];

        // Set the person
        ABRecordRef contactRef = ABPersonCreate();
        
#warning - Name, number and e-mail properties of the unknown contact
        // Set a name
        //ABRecordSetValue(contactRef, kABPersonFirstNameProperty, (__bridge CFTypeRef)@"FirstName", NULL);
        //ABRecordSetValue(contactRef, kABPersonLastNameProperty, (__bridge CFTypeRef)@"LastName", NULL);
        
        // Set a message
        //[personViewController setMessage:@"Message"];
        
        // Set a number
        ABMutableMultiValueRef numberMulti = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        if (firstRecent.dialedNumber == nil)
        {
            ABMultiValueAddValueAndLabel(numberMulti, (__bridge CFTypeRef)@"anonymous", kABOtherLabel, NULL);
        }
        else
        {
            ABMultiValueAddValueAndLabel(numberMulti, (__bridge CFTypeRef)firstRecent.dialedNumber, kABOtherLabel, NULL);
        }
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
        recentViewController = [[NBRecentContactViewController alloc] init];
        [recentViewController setDisplayedPerson:[self getContactForID:firstRecent.contactId]];
        
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

- (ABRecordRef)getContactForID:(NSString*)contactId
{
    ABRecordID recordID = [contactId intValue];
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
    NSFetchRequest* fetchRequest = fetchedResultsController.fetchRequest;

    switch (callSelection)
    {
        case CallSelectionAll:      [fetchRequest setPredicate:nil];                    break;
        case CallSelectionOutgoing: [fetchRequest setPredicate:outgoingCallsPredicate]; break;
        case CallSelectionIncoming: [fetchRequest setPredicate:incomingCallsPredicate]; break;
        case CallSelectionMissed:   [fetchRequest setPredicate:missedCallsPredicate];   break;
    }

    return fetchedResultsController;
}


- (void)performFetchWithForce:(BOOL)force
{
    NSFetchedResultsController* fetchedController = [self fetchedResultsController];
    NSError* error;
    [fetchedController performFetch:&error];
    if (error)
    {
        NBLog(@"%@", [error localizedDescription]);
    }
    else
    {
        [self reloadForce:force];
    }
}


#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self reloadForce:NO];
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
