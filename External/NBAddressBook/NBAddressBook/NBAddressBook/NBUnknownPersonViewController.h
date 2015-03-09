//
//  NBUnknownPersonViewController.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/12/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//
//  Displaying an unknown contact

#import "NBPersonViewController.h"
#import "NBNewPersonViewController.h"
#import "NBPeopleListViewController.h"
#import "NBPeoplePickerNavigationController.h"
#import "NBUnknownPersonViewControllerDelegate.h"
#import "NBRecentContactViewController.h"

@interface NBUnknownPersonViewController : NBPersonViewController <NBNewPersonViewControllerDelegate>
{
    //Can be either a name or a phone number
    NSMutableAttributedString * personRepresentation;
    
    //E-mail address (if the person has one)
    NSString * emailAddress;
    
    //Number (if the person has one)
    NSString * number;
    
    //The navigationcontroller pushed
    UINavigationController * navController;
}

//A text message shown below the alternate name
@property (nonatomic) NSString * message;

//Wether it is allowed to add this item to the address book
@property (nonatomic) BOOL allowsAddingToAddressBook;

@property (nonatomic) BOOL allowsSendingMessage;

@property (nonatomic) id<NBUnknownPersonViewControllerDelegate> unknownPersonViewDelegate;

@end
