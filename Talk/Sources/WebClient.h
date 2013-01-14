//
//  WebClient.h
//  Talk
//
//  Created by Cornelis van der Bent on 10/01/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "AFHTTPClient.h"

@interface WebClient : AFHTTPClient

+ (WebClient*)sharedClient;

- (void)postAccounts:(NSDictionary*)parameters
             success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success
             failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure;

@end
