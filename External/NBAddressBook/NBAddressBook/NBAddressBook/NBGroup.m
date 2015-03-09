//
//  NBGroup.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/14/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import "NBGroup.h"

@implementation NBGroup

#pragma mark - Initialization

- (instancetype)init
{
    if (self = [super init])
    {
        _memberContacts = [NSMutableArray array];
    }

    return self;
}

@end
