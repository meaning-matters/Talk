//
//  NBPeoplePickerNavigationController.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/1/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "NBPeoplePickerNavigationController.h"

@interface NBPeoplePickerNavigationController ()
{
    NBPeopleListViewController* listViewController;
}

@end

@implementation NBPeoplePickerNavigationController

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

@end
