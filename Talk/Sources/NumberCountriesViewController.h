//
//  NumberCountriesViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 05/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NumberCountriesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,
                                                             UISearchBarDelegate, UIScrollViewDelegate>

@property (nonatomic, weak) IBOutlet UINavigationBar*   navigationBar;
@property (nonatomic, weak) IBOutlet UISearchBar*       searchBar;
@property (nonatomic, weak) IBOutlet UITableView*       tableView;


- (IBAction)cancelAction:(id)sender;

@end
