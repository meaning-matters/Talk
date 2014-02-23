//
//  NumberCountriesViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 05/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface NumberCountriesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,
                                                             UISearchDisplayDelegate, UISearchBarDelegate>

@property (nonatomic, retain) IBOutlet UITableView* tableView;

@end
