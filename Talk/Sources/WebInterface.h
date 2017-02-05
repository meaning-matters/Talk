//
//  WebInterface.h
//  Talk
//
//  Created by Cornelis van der Bent on 9/9/14.
//  Copyright (c) 2014 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPSessionManager.h"

typedef NS_ENUM(NSUInteger, RequestMethod)
{
    RequestMethodGet    = 1,
    RequestMethodPost   = 2,
    RequestMethodPut    = 3,
    RequestMethodDelete = 4,
};


@interface WebInterface : AFHTTPSessionManager

@property (atomic, assign) BOOL forceServerUpdate;


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

- (void)cancelAllHttpRequestsWithMethod:(RequestMethod)method path:(NSString*)path;

- (void)cancelAllHttpRequests;

@end
