//
//  FailoverWebInterface.h
//  Talk
//
//  Created by Dev on 9/9/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import "AFHTTPRequestOperationManager.h"
#import "FailoverOperation.h"


@protocol FailoverDelegate <NSObject>

- (NSString*)modifyServer:(NSString*)server;

- (BOOL)checkReplyContent:(id)content;

- (NSString*)webUsername;

- (NSString*)webPassword;

@end


@interface FailoverWebInterface : AFHTTPRequestOperationManager

@property (atomic, copy)      NSString*            dnsHost;
@property (atomic, weak)      id<FailoverDelegate> delegate;
@property (nonatomic, assign) NSTimeInterval       timeout;  // Seconds.
@property (nonatomic, assign) NSUInteger           retries;  // Number of times a server is retried.
@property (nonatomic, assign) NSTimeInterval       delay;    // Delay between retries.


+ (FailoverWebInterface*)sharedInterface;

- (NSString*)getServer;

- (void)networkRequestFail:(FailoverOperation*)notificationOperation;

- (void)reorderServersWithSuccess:(BOOL)success;

- (void)getPath:(NSString*)path
     parameters:(id)parameters
        success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success
        failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure;

- (void)postPath:(NSString*)path
      parameters:(id)parameters
         success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success
         failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure;

- (void)putPath:(NSString*)path
     parameters:(id)parameters
        success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success
        failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure;

- (void)deletePath:(NSString*)path
        parameters:(id)parameters
           success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success
           failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure;

- (void)cancelAllHTTPOperationsWithMethod:(NSString*)method path:(NSString*)path;

@end
