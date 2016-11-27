//
//  NBRecentUnknownContactViewController.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/20/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "NBRecentUnknownContactViewController.h"


@interface NBRecentUnknownContactViewController ()
{
    //The recent entry the calls displayed are based on
    NSArray*        recents;

    //The outgoing and incoming calls
    NSMutableArray* outgoingCalls;
    NSMutableArray* incomingCalls;
}

@end


@implementation NBRecentUnknownContactViewController

@synthesize addUnknownContactDelegate;

#pragma mark - Initialization

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Clear the footer
    [self.tableView setTableFooterView:nil];

    self.navigationItem.rightBarButtonItem = nil;
}


- (void)setRecents:(NSArray*)theRecents
{
    recents = theRecents;

    // If the last call received was missed, mark as such.
    incomingCalls = [NSMutableArray array];
    outgoingCalls = [NSMutableArray array];

    for (CallRecordData* entry in recents)
    {
        switch ([entry.direction intValue])
        {
            case CallDirectionIncoming:
            {
                [incomingCalls addObject:entry];
                break;
            }
            case CallDirectionOutgoing:
            {
                [outgoingCalls addObject:entry];
                break;
            }
        }
    }
}


/*#####
#pragma mark - New contact added/merged
- (void)newPersonViewController:(NBNewPersonViewController *)newPersonViewController didCompleteWithNewPerson:(ABRecordRef)contactRef
{
    //Always call the super
    [super newPersonViewController:newPersonViewController didCompleteWithNewPerson:contactRef];
    
    //Store this info in CoreData
    CallRecordData* firstRecent = [recents objectAtIndex:0];
    [firstRecent setContactID:[NSString stringWithFormat:@"%d", ABRecordGetRecordID(contactRef)]];
#if NB_STANDALONE
    [((NBAppDelegate*)[[UIApplication sharedApplication] delegate]) saveContext];
#else
    [[NBAddressBookManager sharedManager].delegate saveContext];
#endif

    //Set a new viewcontroller
    NBRecentContactViewController * personViewController = [[NBRecentContactViewController alloc] init];
    [personViewController setDisplayedPerson:contactRef];
    [personViewController setRecents:recents];

    id<NBAddUnknownContactDelegate> contactDelegate = self.addUnknownContactDelegate;
    [self setAddUnknownContactDelegate:nil];
    [contactDelegate replaceViewController:personViewController];
}
*/


#pragma mark - Tableview overloading - Received/made calls-section

- (CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section
{
    // Only show the recent calls when not editing
    if (section == CC_FILLER && !self.tableView.isEditing )
    {
        CGFloat incomingHeight = [incomingCalls count] > 0 ? ( [incomingCalls count] * HEIGHT_CALL_ENTRY) + HEIGHT_CALL_INFO_HEADER : 0;
        CGFloat outgoingHeight = [outgoingCalls count] > 0 ? ( [outgoingCalls count] * HEIGHT_CALL_ENTRY) + HEIGHT_CALL_INFO_HEADER : 0;

        return incomingHeight + outgoingHeight + PADDING_CALLS_VIEW;
    }
    else
    {
        return [super tableView:tableView heightForFooterInSection:section];
    }
}


- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section
{
    if (section == CC_FILLER && !self.tableView.isEditing )
    {
        // Build up the non-interactive missed calls-view
        CallRecordData* firstRecent = [recents objectAtIndex:0];
        CGFloat         height      = [self tableView:tableView heightForFooterInSection:section];
        UIView*         footerView  = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                               0,
                                                                               self.view.frame.size.width,
                                                                               height)];
        NBCallsView*    callsView  = [[NBCallsView alloc] initWithFrame:CGRectMake(0,
                                                                                   0,
                                                                                   self.view.frame.size.width,
                                                                                   height - (PADDING_CALLS_VIEW * 0.77f) )
                                                                 recent:firstRecent
                                                          incomingCalls:incomingCalls
                                                          outgoingCalls:outgoingCalls
                                                                editing:NO];
        [callsView setBackgroundColor:[UIColor clearColor]];
        
        callsView.center = CGPointMake(footerView.center.x, footerView.center.y  );
        [footerView addSubview:callsView];
        
        return footerView;
    }
    else
    {
        return nil;
    }
}

@end
