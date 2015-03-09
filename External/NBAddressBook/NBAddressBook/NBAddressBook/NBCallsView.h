//
//  NBCallsView.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/24/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NBRecentContactEntry.h"

#define HEIGHT_CALL_INFO_HEADER     25
#define HEIGHT_CALL_ENTRY           20
#define PADDING_CALLS_VIEW          40
#define CALLS_AREA_INSET            10


@interface NBCallsView : UIView

- (instancetype)initWithFrame:(CGRect)frame
                  recentEntry:(NBRecentContactEntry*)recentEntry
                incomingCalls:(NSMutableArray*)incomingCalls
                outgoingCalls:(NSMutableArray*)outgoingCalls
                      editing:(BOOL)editing;

@end
