//
//  NumbersViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NumbersViewController : UITableViewController

- (void)refresh:(id)sender;

- (NSError*)fetchData;

@end
