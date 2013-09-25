//
//  NumbersViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"

@interface NumbersViewController : ViewController <UITableViewDataSource, UITableViewDelegate,
                                                   UISearchBarDelegate, UISearchDisplayDelegate>

@property (nonatomic, weak) IBOutlet UITableView*   tableView;

- (void)refresh:(id)sender;

- (NSError*)fetchData;

@end
