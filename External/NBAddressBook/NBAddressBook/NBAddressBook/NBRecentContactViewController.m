//
//  NBRecentContactViewController.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/20/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import "NBRecentContactViewController.h"

@interface NBRecentContactViewController ()
{
    //The recent entry the calls displayed are based on
    NSArray * recentEntryArray;

    //The outgoing and incoming calls
    NSMutableArray * incomingCalls;
    NSMutableArray * outgoingCalls;
}

@end


@implementation NBRecentContactViewController

- (void)setRecentEntryArray:(NSArray*)theEntryArray
{
    recentEntryArray = theEntryArray;

    // If the last call received was missed, mark as such
    incomingCalls = [NSMutableArray array];
    outgoingCalls = [NSMutableArray array];
    for (NBRecentContactEntry* entry in recentEntryArray)
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

/*
- (void)setRecentEntryArray:(NSArray*)entryArrayParam
{
    //Remember the entry
    recentEntryArray = entryArrayParam;
    
    //If the last call received was missed, mark as such
    incomingCalls = [NSMutableArray array];
    outgoingCalls = [NSMutableArray array];
    for (NBRecentContactEntry * entry in recentEntryArray)
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

#pragma mark - Tableview methods overloaded for the calls-section
- (CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == CC_NAME  && !self.tableView.isEditing )
    {
        int incomingHeight = [incomingCalls count] > 0 ?  ( [incomingCalls count] * HEIGHT_CALL_ENTRY) + HEIGHT_CALL_INFO_HEADER : 0;
        int outgoingHeight = [outgoingCalls count] > 0 ?  ( [outgoingCalls count] * HEIGHT_CALL_ENTRY) + HEIGHT_CALL_INFO_HEADER : 0;
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
        NBRecentContactEntry* firstEntry = [recentEntryArray objectAtIndex:0];
        CGFloat               height     = [self tableView:tableView heightForFooterInSection:section];
        UIView * footerView = [[UIView alloc]initWithFrame:CGRectMake(
                                                                      0,
                                                                      0,
                                                                      self.view.frame.size.width,
                                                                      height)];
        NBCallsView*          callsView  = [[NBCallsView alloc]initWithFrame:CGRectMake(
                                                                                        0,
                                                                                        0,
                                                                                        self.view.frame.size.width,
                                                                                        height - (PADDING_CALLS_VIEW*0.77f))
                                                                 recentEntry:firstEntry
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


//Method overloaded to color the cell of the number that was called
- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.section == CC_NUMBER )
    {
        NBDetailLineSeparatedCell * cell = (NBDetailLineSeparatedCell*)[super tableView:tableView cellForRowAtIndexPath:indexPath];
        NBRecentContactEntry * entry = [recentEntryArray objectAtIndex:0];
        
        //If this was the called number
        if ([entry.number isEqualToString:cell.cellTextfield.text])
        {
            //If the call was missed, color it dark red
            if ([entry.status intValue] == CallStatusMissed)
            {
                [cell.cellTextfield setTextColor:FONT_COLOR_MISSED];                
            }
            //If the call was received/made, color it blue
            else
            {
                [cell.cellTextfield setTextColor:FONT_COLOR_MERGED];
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
