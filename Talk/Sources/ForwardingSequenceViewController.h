//
//  ForwardingSequenceViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 30/04/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ForwardingData.h"


@interface ForwardingSequenceViewController : UITableViewController

- (instancetype)initWithFetchedResultsController:(NSFetchedResultsController*)resultsController
                                      forwarding:(ForwardingData*)theForwarding
                                    rootSequence:(NSMutableArray*)theRootSequence
                                        sequence:(NSMutableArray*)theSequence;
@end
