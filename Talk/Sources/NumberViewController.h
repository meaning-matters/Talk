//
//  NumberViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 27/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NumberData.h"


@interface NumberViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate,
                                                    UIGestureRecognizerDelegate, UINavigationControllerDelegate>

@property (nonatomic, weak) IBOutlet UITableView*   tableView;

- (instancetype)initWithNumber:(NumberData*)number;

@end
