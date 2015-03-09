//
//  NBNewPersonViewController.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/12/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//
//  Class to display adding a new person to the address book

#import "NBPersonViewController.h"
#import "NBNewPersonViewControllerDelegate.h"

@interface NBNewPersonViewController : NBPersonViewController

//Delegate called when adding a contact is completed
@property (nonatomic, assign) id<NBNewPersonViewControllerDelegate> aNewPersonViewDelegate;

@end
 