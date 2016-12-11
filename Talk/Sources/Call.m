//
//  Call.m
//  Talk
//
//  Created by Cornelis van der Bent on 04/12/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import "Call.h"

@implementation Call

- (instancetype)initWithPhoneNumber:(PhoneNumber*)phoneNumber direction:(CallDirection)direction
{
    if (self = [super init])
    {
        _phoneNumber  = phoneNumber;        
        _beginDate    = [NSDate date];
        _state        = CallStateNone;
        _leg          = CallLegNone;
        _direction    = direction;
        _network      = CallNetworkInternet; // Default.
    }

    return self;
}

@end
