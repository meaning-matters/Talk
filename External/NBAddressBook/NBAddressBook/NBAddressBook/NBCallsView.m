//
//  NBCallsView.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/24/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "NBCallsView.h"


@implementation NBCallsView

- (instancetype)initWithFrame:(CGRect)frame
                  recentEntry:(NBRecentContactEntry*)recentEntry
                incomingCalls:(NSMutableArray*)incomingCalls
                outgoingCalls:(NSMutableArray*)outgoingCalls
                      editing:(BOOL)editing
{
    if (self = [super initWithFrame:frame])
    {
        //Clear the back
        [self setBackgroundColor:[UIColor clearColor]];
        
        //In case of editing, shift the tableview down a little
        int yShift = editing ? 10 : 0;
        
        //Add a top separator
        UIView* topSeparator = [[UIView alloc] initWithFrame:CGRectMake(CALLS_AREA_INSET,
                                                                         2,
                                                                         self.frame.size.width - 2 * CALLS_AREA_INSET,
                                                                         1)];
        topSeparator.backgroundColor = [UIColor lightGrayColor];
        UIView* secondTopSeparator = [[UIView alloc] initWithFrame:CGRectOffset(topSeparator.frame, 0, 1)];
        secondTopSeparator.backgroundColor = [UIColor whiteColor];
        [secondTopSeparator setAlpha:0.33f];
        [self addSubview:topSeparator];
        [self addSubview:secondTopSeparator];
        
        //Show the date topright
        UILabel* dateLabel = [[UILabel alloc]initWithFrame:CGRectMake(self.frame.size.width / 2, 5 + yShift, 150, 20)];
        [dateLabel setBackgroundColor:[UIColor clearColor]];
        [dateLabel setText:[NSString formatToShortDate:recentEntry.date]];
        [dateLabel setFont:[UIFont boldSystemFontOfSize:15]];
        [dateLabel setTextAlignment:NSTextAlignmentRight];
        [self addSubview:dateLabel];
        
        //Draw the incoming calls (if any)
        int yStart = 5 + yShift;
        if ([incomingCalls count] > 0)
        {
            yStart = [self drawCalls:incomingCalls startingAt:yStart areIncomingCalls:YES] + HEIGHT_CALL_INFO_HEADER;
        }
        
        if ([outgoingCalls count] > 0)
        {
            [self drawCalls:outgoingCalls startingAt:yStart areIncomingCalls:NO];
        }
        
        //Add a bottom separators
        UIView* bottomSeparator = [[UIView alloc] initWithFrame:CGRectMake(CALLS_AREA_INSET,
                                                                           self.frame.size.height - 1,
                                                                           self.frame.size.width - 2 * CALLS_AREA_INSET,
                                                                           1)];
        bottomSeparator.backgroundColor = [UIColor lightGrayColor];
        UIView * secondBottomSeparator = [[UIView alloc] initWithFrame:CGRectOffset(bottomSeparator.frame, 0, 1)];
        secondBottomSeparator.backgroundColor = [UIColor whiteColor];
        [secondBottomSeparator setAlpha:0.33f];
        [self addSubview:bottomSeparator];
        [self addSubview:secondBottomSeparator];
    }

    return self;
}


- (int)drawCalls:(NSMutableArray*)calls startingAt:(int)yStart areIncomingCalls:(BOOL)areIncomingCalls
{
    // Create the label
    UILabel* callsLabel = [[UILabel alloc]initWithFrame:CGRectMake(CALLS_AREA_INSET, yStart, 150, 20)];
    [callsLabel setBackgroundColor:[UIColor clearColor]];
    [callsLabel setText:areIncomingCalls ? NSLocalizedString(@"RCD_INCOMING_CALLS", @"") : NSLocalizedString(@"RCD_OUTGOING_CALLS", @"")];
    [callsLabel setFont:[UIFont boldSystemFontOfSize:15]];
    [callsLabel setTextAlignment:NSTextAlignmentLeft];
    [self addSubview:callsLabel];
    
    // Create a line for each of the entries
    for (NBRecentContactEntry* recent in calls)
    {
        // Swich down the label
        yStart += HEIGHT_CALL_ENTRY;
        
        // Create the label
        UILabel*  timeLabel   = [self createLabelAtX:0   y:yStart width:45  alignment:NSTextAlignmentLeft];
        UILabel*  statusLabel = [self createLabelAtX:75  y:yStart width:125 alignment:NSTextAlignmentLeft];
        UILabel*  costLabel   = [self createLabelAtX:200 y:yStart width:100 alignment:NSTextAlignmentRight];

        NSString* timeString;
        NSString* statusString;
        NSString* costString;

        timeString = [NSString formatToTime:recent.date];

        int duration = [recent.outgoingDuration intValue];
        switch ([recent.status intValue])
        {
            case CallStatusMissed:    statusString = NSLocalizedString(@"RCD_MISSED",    @"");  break;
            case CallStatusFailed:    statusString = NSLocalizedString(@"RCD_FAILED",    @"");  break;
            case CallStatusDeclined:  statusString = NSLocalizedString(@"RCD_DECLINED",  @"");  break;
            case CallStatusBusy:      statusString = NSLocalizedString(@"RCD_BUSY",      @"");  break;
            case CallStatusCancelled: statusString = NSLocalizedString(@"RCD_CANCELLED", @"");  break;
            case CallStatusCallback:  statusString = NSLocalizedString(@"RCD_CALLBACK",  @"");  break;
            case CallStatusSuccess:   statusString = [self durationStringForDuration:duration]; break;
        }

        NBAddressBookManager* manager = [NBAddressBookManager sharedManager];
        float cost = [recent.callbackCost floatValue] + [recent.outgoingCost floatValue];
        if (cost != 0)
        {
            costString = [manager.delegate localizedFormattedPrice2ExtraDigits:cost];
        }
        else
        {
            costString = @"";
        }

        if (recent.uuid == nil)
        {
            // Call is ready and data is up to date.
            timeLabel.text   = timeString;
            statusLabel.text = statusString;
            costLabel.text   = costString;
        }
        else
        {
            timeLabel.text   = timeString;

            UIActivityIndicatorView* statusIndicator = [self createActivityIndicatorAtX:75  y:yStart];
            statusLabel.text = @"";
            costLabel.text   = @"";

            [manager.delegate updateRecent:recent completion:^(BOOL success, BOOL ended)
            {
                if (success)
                {
                    if (ended)
                    {
                        [statusIndicator stopAnimating];

                        if ([recent.callbackCost floatValue] == 0)
                        {
                            statusLabel.text = NSLocalizedString(@"RCD_CANCELLED", @""); // Best guess.
                        }
                        else if ([recent.outgoingCost floatValue] == 0)
                        {
                            statusLabel.text = NSLocalizedString(@"RCD_CALLBACK",  @"");

                            float cost       = [recent.callbackCost floatValue];
                            costLabel.text   = [manager.delegate localizedFormattedPrice2ExtraDigits:cost];
                        }
                        else
                        {
                            statusLabel.text = [self durationStringForDuration:[recent.outgoingDuration intValue]];

                            float cost       = [recent.callbackCost floatValue] + [recent.outgoingCost floatValue];
                            costLabel.text   = [manager.delegate localizedFormattedPrice2ExtraDigits:cost];
                        }
                    }
                }
                else
                {
                    [statusIndicator stopAnimating];

                    statusLabel.text      = NSLocalizedString(@"RCD_NOT_UPTODATE", @"");
                    statusLabel.textColor = [manager.delegate deleteTintColor];
                }
            }];
        }
    }

    return yStart;
}


- (NSString*)durationStringForDuration:(int)duration
{
    NSString* durationUnit;

    if (duration > 60 * 60)
    {
        duration /= (60 * 60);
        if (duration == 1)
        {
            durationUnit = NSLocalizedString(@"RCD_HOUR", @"");
        }
        else
        {
            durationUnit = NSLocalizedString(@"RCD_HOURS", @"");
        }
    }
    else if (duration > 60)
    {
        duration /= 60;
        if (duration == 1)
        {
            durationUnit = NSLocalizedString(@"RCD_MINUTE", @"");
        }
        else
        {
            durationUnit = NSLocalizedString(@"RCD_MINUTES", @"");
        }
    }
    else
    {
        if (duration == 1)
        {
            durationUnit = NSLocalizedString(@"RCD_SECOND", @"");
        }
        else
        {
            durationUnit = NSLocalizedString(@"RCD_SECONDS", @"");
        }
    }

    return [NSString stringWithFormat:@"%d %@", duration, durationUnit];
}


- (UILabel*)createLabelAtX:(CGFloat)x y:(CGFloat)y width:(CGFloat)width alignment:(NSTextAlignment)alignment
{
    UILabel* label        = [[UILabel alloc]initWithFrame:CGRectMake(CALLS_AREA_INSET + x, y, width, 20)];

    label.backgroundColor = [UIColor clearColor];
    label.font            = [UIFont systemFontOfSize:15];
    label.textAlignment   = alignment;

    [self addSubview:label];

    return label;
}


- (UIActivityIndicatorView*)createActivityIndicatorAtX:(CGFloat)x y:(CGFloat)y
{
    UIActivityIndicatorView* activityIndicator;

    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self addSubview:activityIndicator];
    activityIndicator.center = CGPointMake(CALLS_AREA_INSET + x + activityIndicator.frame.size.width / 2, y + 1 + 20 / 2);
    [activityIndicator startAnimating];

    return activityIndicator;
}

@end
