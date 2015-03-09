//
//  NBPeoplePickerNavigationController.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/1/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NBPeopleListViewController.h"
#import "NBPeoplePickerNavigationControllerDelegate.h"


@interface NBPeoplePickerNavigationController : UINavigationController

@property (nonatomic) id<NBPeoplePickerNavigationControllerDelegate> peoplePickerDelegate;

- (id)listViewController;

@end
