//
//  AFHTTPRequestOperationFailover.h
//  Talk
//
//  Created by Dev on 9/10/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import "AFHTTPRequestOperation.h"

typedef void (^originalSuccessBlock)(AFHTTPRequestOperation* operation, id responseObject);
typedef void (^originalFailureBlock)(AFHTTPRequestOperation* operation, id responseObject);

@interface FailoverOperation : AFHTTPRequestOperation

@property (nonatomic, copy) originalSuccessBlock success;
@property (nonatomic, copy) originalFailureBlock failure;

+ (instancetype)initWithOperation:(AFHTTPRequestOperation*)operation;
+ (instancetype)initWithOperation:(AFHTTPRequestOperation*)operation request:(NSURLRequest*)request;

+ (BOOL)hasIgnoreStartHeader:(NSDictionary*)dictionary;

@end
