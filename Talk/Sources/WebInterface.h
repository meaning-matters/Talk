//
//  WebInterface.h
//  Talk
//
//  Created by Cornelis van der Bent on 9/9/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import "AFHTTPRequestOperationManager.h"


@interface WebInterface : AFHTTPRequestOperationManager

+ (WebInterface*)sharedInterface;

- (void)postPath:(NSString*)path
      parameters:(NSDictionary*)parameters
           reply:(void (^)(NSError* error, id content))reply;

- (void)putPath:(NSString*)path
     parameters:(NSDictionary*)parameters
          reply:(void (^)(NSError* error, id content))reply;

- (void)getPath:(NSString*)path
     parameters:(NSDictionary*)parameters
          reply:(void (^)(NSError* error, id content))reply;

- (void)deletePath:(NSString*)path
        parameters:(NSDictionary*)parameters
             reply:(void (^)(NSError* error, id content))reply;

- (void)cancelAllHttpOperationsWithMethod:(NSString*)method path:(NSString*)path;

- (void)cancelAllHttpOperations;

@end
