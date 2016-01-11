//
//  NBPeoplePickerNavigationController.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/1/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NBPeopleListViewController.h"
#import "NBPeoplePickerNavigationControllerDelegate.h"


@interface NBPeoplePickerNavigationController : UINavigationController

- (id)listViewController;

@end
