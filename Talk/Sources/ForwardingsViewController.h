//
//  ForwardingsViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"


@interface ForwardingsViewController : ViewController <UITableViewDataSource, UITableViewDelegate,
                                                       NSFetchedResultsControllerDelegate>

@property (nonatomic, weak) IBOutlet UITableView*   forwardingsTableView;
@property (nonatomic, weak) IBOutlet UITableView*   recordingsTableView;

@end
