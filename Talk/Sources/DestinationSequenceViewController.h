//
//  DestinationSequenceViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 30/04/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DestinationData.h"


@interface DestinationSequenceViewController : UITableViewController

- (instancetype)initWithFetchedResultsController:(NSFetchedResultsController*)resultsController
                                     destination:(DestinationData*)theDestination
                                    rootSequence:(NSMutableArray*)theRootSequence
                                        sequence:(NSMutableArray*)theSequence;
@end
