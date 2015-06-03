//
//  WebInterface.h
//  Talk
//
//  Created by Dev on 9/9/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import "AFHTTPRequestOperationManager.h"


@protocol WebInterfaceDelegate <NSObject>

- (NSString*)modifyServer:(NSString*)server;

- (BOOL)checkReplyContent:(id)content;

- (NSString*)webUsername;

- (NSString*)webPassword;

@end


@interface WebInterface : AFHTTPRequestOperationManager

@property (atomic, weak) id<WebInterfaceDelegate> delegate;


+ (WebInterface*)sharedInterface;

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

- (void)cancelAllHttpOperationsWithMethod:(NSString*)method path:(NSString*)path;

- (void)cancelAllHttpOperations;

@end
