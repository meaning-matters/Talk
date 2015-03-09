//
//  NBNewPersonViewController.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/12/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import "NBNewPersonViewController.h"

@implementation NBNewPersonViewController

@synthesize aNewPersonViewDelegate;

#pragma mark - Initialization
- (void)viewDidLoad
{
    [super viewDidLoad];

    //Start in editing-mode
    [self.tableView setEditing:YES animated:YES];
    
    //Set the screen title
    self.navigationItem.title = NSLocalizedString(@"NCT_NEW_CONTACT", @"");

    //Set the cancel and done button
    self.navigationItem.leftBarButtonItem = cancelButton;
    self.navigationItem.rightBarButtonItem = doneButton;
    
    //Allow for setting the portrait
    [portraitButton setImage:portraitLine forState:UIControlStateNormal];
    
    //Hide the delete-button
    self.tableView.tableFooterView = nil;
    
    //Start in viewing-mode
    [self enableEditMode:YES];
    
    //Create a new contact, mark it as such
    [self.contact setIsNewContact:YES];
}

#pragma mark - Reloading contact
- (void)reloadContact
{
    //Leave empty, nothing needs to happen
}

#pragma mark - Button delegates
//Overload the existing button delegate methods
- (void)cancelPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)continueDonePressed
{    
    //Create the contact, save the system and dismiss
    [super continueDonePressed];
    
    //Inform a delegate that we might have
    if (aNewPersonViewDelegate != nil)
    {
        [aNewPersonViewDelegate newPersonViewController:self didCompleteWithNewPerson:self.contact.contactRef];
    }
}

@end
