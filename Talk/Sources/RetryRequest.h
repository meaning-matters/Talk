//
//  RetryRequest.h
//  Talk
//
//  Created by Dev on 9/3/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FailoverWebInterface.h"
#import "FailoverOperation.h"

@interface RetryRequest : NSObject

@property (nonatomic, strong) NSDate* startTime;

- (void)tryMakeRequest:(AFHTTPRequestOperation*)operation;

@end

