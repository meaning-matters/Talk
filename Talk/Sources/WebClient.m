//
//  WebClient.m
//  Talk
//
//  Created by Cornelis van der Bent on 10/01/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "WebClient.h"
#import "AFJSONRequestOperation.h"
#import "Settings.h"
#import "Common.h"


@implementation WebClient

static WebClient*   sharedClient;

#pragma mark - Singleton Stuff

+ (void)initialize
{
    if ([WebClient class] == self)
    {
        sharedClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:[Settings sharedSettings].webBaseUrl]];
        [sharedClient setParameterEncoding:AFJSONParameterEncoding];
        [sharedClient setDefaultHeader:@"Accept" value:@"application/json"];
        [sharedClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [sharedClient setAuthorizationHeaderWithUsername:[Settings sharedSettings].webUsername
                                                password:[Settings sharedSettings].webPassword];
    }
}


+ (id)allocWithZone:(NSZone*)zone
{
    if (sharedClient && [WebClient class] == self)
    {
        [NSException raise:NSGenericException format:@"Duplicate WebClient singleton creation"];
    }

    return [super allocWithZone:zone];
}


+ (WebClient*)sharedClient
{
    return sharedClient;
}


- (void)postAccounts:(NSDictionary*)parameters
             success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success
             failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure
{
    [self postPath:@"accounts"
        parameters:parameters
           success:^(AFHTTPRequestOperation* operation, id responseObject)
    {
        NSLog(@"getPath request: %@", operation.request.URL);

        NSDictionary* reponseDictionary = responseObject;
        if(responseObject && [reponseDictionary isKindOfClass:[NSDictionary class]])
        {
            if (success)
            {
                success(operation, reponseDictionary);
            }
        }
        else
        {
            NSString*   errorDomain = [Settings sharedSettings].errorDomain;
            NSError*    error       = [NSError errorWithDomain:errorDomain code:1 userInfo:nil];
            
            if(failure)
            {
                failure(operation, error);
            }
        }
    }
           failure:failure];
}

@end
