//
//  NumberAreaViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 11/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NumberAreaViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView*   tableView;


- (id)initWithCountry:(NSDictionary*)country state:(NSDictionary*)state area:(NSDictionary*)area;

@end
