//
//  NumberAreaCitiesViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 08/04/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface NumberAreaCitiesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,
                                                              UISearchBarDelegate, UISearchDisplayDelegate>

@property (nonatomic, weak) IBOutlet UITableView*   tableView;


- (instancetype)initWithCitiesArray:(NSArray*)array purchaseInfo:(NSMutableDictionary*)info;

@end
