//
//  PhoneNumber.m
//  Talk
//
//  Created by Cornelis van der Bent on 28/10/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "PhoneNumber.h"
#import "PhoneNumberMetaData.h"

@interface PhoneNumber ()
{
    PhoneNumberMetaData*    metaData;
}

@end


@implementation PhoneNumber

- (id)initWithNumber:(NSString*)number
{
    if (self = [super init])
    {
        metaData = [PhoneNumberMetaData sharedInstance];
    }
    
    return self;
}

@end
