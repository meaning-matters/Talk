//
//  NBGroup.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/14/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//
//  Group representation containing member contacts and wether the group is selected

#import <Foundation/Foundation.h>

@interface NBGroup : NSObject

@property (nonatomic) NSString*       groupName;
@property (nonatomic) NSMutableArray* memberContacts;
@property (nonatomic) BOOL            groupSelected;

@end
