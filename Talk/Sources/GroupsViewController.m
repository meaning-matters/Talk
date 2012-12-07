//
//  GroupsViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

//### Have a look at this (http://stackoverflow.com/questions/9859639/ios-bridge-vs-bridge-transfer):
/*
-(void)getData{
    ABAddressBookRef addressBook = ABAddressBookCreate();
    NSArray *allPeople = (__bridge_transfer NSArray*)ABAddressBookCopyArrayOfAllPeople(addressBook);

    NSString *name;
    for ( int i = 0; i < [allPeople count]; i++ )
    {
        name = (__bridge_transfer NSString *) ABRecordCopyValue((__bridge ABRecordRef)[allPeople objectAtIndex:i], kABPersonFirstNameProperty);
    }
    CFRelease(addressBook);
    allPeople = nil;
}
*/
 
 
#import "GroupsViewController.h"

@interface GroupsViewController ()

@end


@implementation GroupsViewController

@synthesize textField = _textField;

- (id)init
{
    if (self = [super initWithNibName:@"GroupsView" bundle:nil])
    {
        self.title = NSLocalizedString(@"Groups", @"Groups tab title");
        self.tabBarItem.image = [UIImage imageNamed:@"GroupsTab.png"];
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
