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
                                                        UITextFieldDelegate, UIGestureRecognizerDelegate,
                                                        UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, weak) IBOutlet UITableView*   tableView;


- (id)initWithIsoCountryCode:(NSString*)isoCountryCode
                       state:(NSDictionary*)state
                        area:(NSDictionary*)area
              numberTypeMask:(NumberTypeMask)numberTypeMask;

@end
