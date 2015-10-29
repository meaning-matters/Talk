//
//  CallerIdViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 15/06/14.
//  Copyright (c) 2014 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CallerIdData;
@class CallableData;


@interface CallerIdViewController : UITableViewController

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                                    callerId:(CallerIdData*)callerId
                            selectedCallable:(CallableData*)selectedCallable
                                   contactId:(NSString*)contactId   // When nil puts it in Settings > Caller ID mode.
                                  completion:(void (^)(CallableData*  selectedCallable, BOOL showCallerId))completion;

@end
