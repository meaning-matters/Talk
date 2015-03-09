//
//  NBPeoplePickerNavigationController.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/1/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import "NBPeoplePickerNavigationController.h"

@interface NBPeoplePickerNavigationController ()
{
    NBPeopleListViewController* listViewController;
}

@end

@implementation NBPeoplePickerNavigationController

@synthesize peoplePickerDelegate;

- (instancetype)init
{
    //Initialize with the list of people.
    if (self = [super initWithRootViewController:(listViewController = [[NBPeopleListViewController alloc] init])] )
    {
        self.title            = NSLocalizedString(@"CNT_TITLE", @"");
        self.tabBarItem.image = [UIImage imageNamed:@"ContactsTab.png"];

        // self.listViewController
    }

    return self;
}


- (id)listViewController
{
    return listViewController;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //Set the delegate if one was set
    [[self.viewControllers objectAtIndex:0] setPeoplePickerDelegate:peoplePickerDelegate];
}

@end
