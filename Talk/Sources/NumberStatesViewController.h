//
//  NumberStatesViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 06/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NumberType.h"

@interface NumberStatesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,
                                                          UISearchBarDelegate, UISearchDisplayDelegate>

- (instancetype)initWithIsoCountryCode:(NSString*)isoCountryCode
                        numberTypeMask:(NumberTypeMask)numberTypeMask;


@property (nonatomic, weak) IBOutlet UITableView*   tableView;

@end
