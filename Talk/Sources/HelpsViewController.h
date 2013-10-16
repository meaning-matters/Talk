//
//  HelpsViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "ViewController.h"

@interface HelpsViewController : ViewController <UITableViewDataSource, UITableViewDelegate,
                                                 MFMailComposeViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UITableView* tableView;

@end
