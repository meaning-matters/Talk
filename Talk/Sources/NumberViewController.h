//
//  NumberViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 27/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NumberData.h"


@interface NumberViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITableView*   tableView;

// NumberHeaderView outlets.
@property (nonatomic, weak) IBOutlet UIView*        tableHeaderView;
@property (nonatomic, weak) IBOutlet UITextField*   nameTextField;
@property (nonatomic, weak) IBOutlet UILabel*       numberLabel;
@property (nonatomic, weak) IBOutlet UIImageView*   flagImageView;
@property (nonatomic, weak) IBOutlet UILabel*       countryLabel;

- (id)initWithNumber:(NumberData*)number;

@end
