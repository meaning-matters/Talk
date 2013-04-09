//
//  NumberAreaViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 11/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NumberType.h"


@interface NumberAreaViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,
                                                        UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITableView*   tableView;


- (id)initWithCountry:(NSDictionary*)theCountry
                state:(NSDictionary*)theState
                 area:(NSDictionary*)theArea
       numberTypeMask:(NumberTypeMask)theNumberTypeMask;

@end
