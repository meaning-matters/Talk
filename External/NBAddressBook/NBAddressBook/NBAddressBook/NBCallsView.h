//
//  NBCallsView.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/24/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CallRecordData.h"

#define HEIGHT_CALL_INFO_HEADER     25
#define HEIGHT_CALL_ENTRY           20
#define PADDING_CALLS_VIEW          40
#define CALLS_AREA_INSET            10


@interface NBCallsView : UIView

- (instancetype)initWithFrame:(CGRect)frame
                  recentEntry:(CallRecordData*)recentEntry
                incomingCalls:(NSMutableArray*)incomingCalls
                outgoingCalls:(NSMutableArray*)outgoingCalls
                      editing:(BOOL)editing;

@end
