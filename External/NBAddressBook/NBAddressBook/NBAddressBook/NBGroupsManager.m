//
//  NBGroupsManager.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/14/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import "NBGroupsManager.h"

@implementation NBGroupsManager

#pragma mark - Initialization
- (instancetype)init
{
    if (self = [super init])
    {
        //If the groups do not exist, create them now
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        
        //Key : group name. Value : dictionary of properties (members & is selected)
        NSMutableDictionary* groupsProperties = [defaults objectForKey:UD_GROUPS];
        if (groupsProperties == nil)
        {
            //Read in the groups from Plist
            groupsProperties = [NSMutableDictionary dictionary];
            NSArray* groupNames = @[@"Group1", @"Group2", @"Group3"];
            for (NSString* groupName in groupNames)
            {
                NSMutableDictionary * propertiesDictionary = [NSMutableDictionary dictionary];
                
                //Initialise group with an empty array and always selected
                [propertiesDictionary setObject:[NSMutableArray array] forKey:PROP_GROUP_CONTACTS];
                [propertiesDictionary setObject:[NSNumber numberWithInt:1] forKey:PROP_GROUP_SELECTED];
                
                //Remember the group and its properties
                [groupsProperties setObject:propertiesDictionary forKey:groupName];
            }

            //Store it in the defaults
            [defaults setObject:groupsProperties forKey:UD_GROUPS];
            [defaults synchronize];
        }
        
        //Convert the user defaults to easy to handle object structure
        self.userGroups = [NSMutableArray array];
        for (NSString* groupName in [groupsProperties allKeys])
        {
            //Retrieve the group properties
            NSDictionary* groupProperties = [groupsProperties objectForKey:groupName];
            
            //Create the easy to manage object
            NBGroup* group = [[NBGroup alloc]init];
            [group setGroupSelected:[[groupProperties objectForKey:PROP_GROUP_SELECTED] intValue]];
            [group setGroupName:groupName];
            [group setMemberContacts:[groupProperties objectForKey:PROP_GROUP_CONTACTS]];
            [self.userGroups addObject:group];
        }
        
        //Listen for adding of users
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addUserToGroup:) name:NF_ADD_TO_GROUP object:nil];
        
        //Listen for saving of usergroups
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveGroups) name:NF_SAVE_GROUPS object:nil];
        
        //Listen for user deletion
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDeleted:) name:NF_USER_DELETED object:nil];
    }

    return self;
}


#pragma mark - Listen for adding users to this group

- (void)addUserToGroup:(NSNotification*)notification
{
    /*  Not sure if the first-and last name will always be available, but this is something to keep in mind
     The recommended way to keep a long-term reference to a particular record is to store the first and last name, or a hash of the first and last name, in addition to the identifier. When you look up a record by ID, compare the record’s name to your stored name. If they don’t match, use the stored name to find the record, and store the new ID for the record.
     */
    NSDictionary* userInfo = notification.userInfo;
    NSString*     contactID = ([userInfo objectForKey:NF_KEY_CONTACT_ID]);
    NSString*     groupName = [userInfo objectForKey:NF_KEY_GROUPNAME];
    BOOL groupsMutated = NO;
    
    //Store the group and save the system
    for (NBGroup* group in self.userGroups)
    {
        if ([group.groupName isEqualToString:groupName])
        {
            if (![group.memberContacts containsObject:contactID])
            {
                groupsMutated = YES;
                [group.memberContacts addObject:contactID];
            }
            break;
        }
    }
    
    //If we mutated the set, save
    if (groupsMutated)
    {
        [self saveGroups];
    }
}


- (void)userDeleted:(NSNotification*)notification
{
    NSString* contactID = notification.object;
    BOOL groupsMutated = NO;
    for (NBGroup* group in self.userGroups)
    {
        if ([group.memberContacts containsObject:contactID])
        {
            groupsMutated = YES;
            [group.memberContacts removeObject:contactID];
        }
    }
    
    //If we mutated the set, save
    if (groupsMutated)
    {
        [self saveGroups];
        
        //Update the list of contacts
        [[NSNotificationCenter defaultCenter] postNotificationName:NF_RELOAD_CONTACTS object:nil];
    }
}


#pragma mark - Group saving

- (void)saveGroups
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    //Convert the groups to properties and store them
    NSMutableDictionary* groupsProperties = [NSMutableDictionary dictionary];
    for (NBGroup* group in self.userGroups)
    {
        NSMutableDictionary* propertiesDictionary = [NSMutableDictionary dictionary];
        [propertiesDictionary setObject:[NSNumber numberWithInt:group.groupSelected ? 1 : 0] forKey:PROP_GROUP_SELECTED];
        [propertiesDictionary setObject:group.memberContacts forKey:PROP_GROUP_CONTACTS];
        [groupsProperties setObject:propertiesDictionary forKey:group.groupName];
    }

    [defaults setObject:groupsProperties forKey:UD_GROUPS];
    [defaults synchronize];
}


#pragma mark - Cleanup

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
