//
//  AFHTTPRequestOperationFailover.h
//  Talk
//
//  Created by Dev on 9/10/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import "AFHTTPRequestOperation.h"

@interface FailoverOperation : AFHTTPRequestOperation

@property (nonatomic, copy) void (^success)(AFHTTPRequestOperation *operation, id responseObject);
@property (nonatomic, copy) void (^failure)(AFHTTPRequestOperation *operation, NSError* error);
@property (nonatomic, strong) NSDate* startTime;
@property (nonatomic, strong) NSMutableDictionary* serverStates;

+ (instancetype)operationWithOperation:(AFHTTPRequestOperation*)operation request:(NSURLRequest*)request;

+ (BOOL)hasIgnoreStartHeader:(NSDictionary*)dictionary;

@end
