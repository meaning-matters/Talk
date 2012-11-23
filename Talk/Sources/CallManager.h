//
//  CallManager.h
//  Talk
//
//  Created by Cornelis van der Bent on 23/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhoneNumber.h"

@interface CallManager : NSObject

+ (CallManager*)sharedManager;

- (BOOL)callPhoneNumber:(PhoneNumber*)phoneNumber;

@end
