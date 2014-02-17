//
//  NumberCountriesViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 05/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface NumberCountriesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,
                                                             UISearchBarDelegate, UISearchDisplayDelegate>

@property (nonatomic, strong) UISegmentedControl* numberTypeSegmentedControl;
@property (nonatomic, weak) IBOutlet UITableView* tableView;

- (void)numberTypeChangedAction:(id)sender;

@end
