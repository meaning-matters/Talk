//
//  NBRecentContactViewController.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/20/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "NBRecentContactViewController.h"

@interface NBRecentContactViewController ()
{
    //The recent entry the calls displayed are based on
    NSArray*        recents;

    //The outgoing and incoming calls
    NSMutableArray* incomingCalls;
    NSMutableArray* outgoingCalls;
}

@end


@implementation NBRecentContactViewController

- (void)setRecents:(NSArray*)theRecents
{
    recents = theRecents;

    // If the last call received was missed, mark as such
    incomingCalls = [NSMutableArray array];
    outgoingCalls = [NSMutableArray array];
    for (CallRecordData* recent in recents)
    {
        switch ([recent.direction intValue])
        {
            case CallDirectionIncoming:
            {
                [incomingCalls addObject:recent];
                break;
            }
            case CallDirectionOutgoing:
            {
                [outgoingCalls addObject:recent];
                break;
            }
        }
    }
}

/*
- (void)setRecents:(NSArray*)recents
{
    //Remember the entry
    recentEntryArray = entryArrayParam;
    
    //If the last call received was missed, mark as such
    incomingCalls = [NSMutableArray array];
    outgoingCalls = [NSMutableArray array];
    for (CallRecordData * recent in recentEntryArray)
    {
        switch ([entry.direction intValue])
        {
            case CallDirectionIncoming:
            {
                [incomingCalls addObject:entry];
            }
                break;
            case CallDirectionOutgoing:
            {
                [outgoingCalls addObject:entry];
            }
                break;
            default:
                break;
        }
    }
}
 */

#pragma mark - Tableview Methods Overloaded For The Calls-section
- (CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == CC_NAME  && !self.tableView.isEditing )
    {
        CGFloat incomingHeight = incomingCalls.count > 0 ?  (incomingCalls.count * HEIGHT_CALL_ENTRY) + HEIGHT_CALL_INFO_HEADER : 0;
        CGFloat outgoingHeight = outgoingCalls.count > 0 ?  (outgoingCalls.count * HEIGHT_CALL_ENTRY) + HEIGHT_CALL_INFO_HEADER : 0;
        return incomingHeight + outgoingHeight + PADDING_CALLS_VIEW;
    }
    else
    {
        return [super tableView:tableView heightForFooterInSection:section];
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    //Only show the recent calls when not editing
    if (section == CC_NAME && !self.tableView.isEditing)
    {
        //Build up the non-interactive missed calls-view
        CallRecordData* firstRecent = [recents objectAtIndex:0];
        CGFloat         height      = [self tableView:tableView heightForFooterInSection:section];
        UIView*         footerView  = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                              0,
                                                                              self.view.frame.size.width,
                                                                              height)];
        NBCallsView*     callsView  = [[NBCallsView alloc] initWithFrame:CGRectMake(0,
                                                                                    0,
                                                                                    self.view.frame.size.width,
                                                                                    height - (PADDING_CALLS_VIEW * 0.77f))
                                                                  recent:firstRecent
                                                           incomingCalls:incomingCalls
                                                           outgoingCalls:outgoingCalls
                                                                 editing:NO];
        [callsView setBackgroundColor:[UIColor clearColor]];
        
        callsView.center = footerView.center;
        [footerView addSubview:callsView];
        
        return footerView;
    }
    else
    {
        return nil;
    }
}


// Method overloaded to color the cell of the number that was called
- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.section == CC_NUMBER )
    {
        NBDetailLineSeparatedCell* cell = (NBDetailLineSeparatedCell*)[super tableView:tableView cellForRowAtIndexPath:indexPath];
        CallRecordData* recent          = [recents objectAtIndex:0];
        
        // If this was the called number
        
        if ([PhoneNumber number:recent.dialedNumber isEqualToNumber:cell.cellTextfield.text])
        {
            // If the call was missed, color it dark red
            if ([recent.status intValue] == CallStatusMissed || [recent.status intValue] == CallStatusDisconnected)
            {
                [cell.cellTextfield setTextColor:[[NBAddressBookManager sharedManager].delegate deleteTintColor]];
            }
            // If the call was received/made, color it blue
            else
            {
                [cell.cellTextfield setTextColor:[[NBAddressBookManager sharedManager].delegate tintColor]];
            }
        }
        
        return cell;
    }
    else
    {
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }
}

@end
