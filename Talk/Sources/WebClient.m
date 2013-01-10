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


@implementation WebClient

static WebClient*   sharedClient;

#pragma mark - Singleton Stuff

+ (void)initialize
{
    if ([Settings class] == self)
    {
        sharedClient = [self new];

        sharedClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:[Settings sharedSettings].webBaseUrl]];
        [sharedClient setParameterEncoding:AFJSONParameterEncoding];
        [sharedClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [sharedClient setAuthorizationHeaderWithUsername:@"" password:@""];
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
             success:(void (^)(AFHTTPRequestOperation* request, NSDictionary* parameters))success
             failure:(void (^)(AFHTTPRequestOperation* request, NSError* error))failure
{
    [self postPath:@"accounts"
        parameters:parameters
           success:^(AFHTTPRequestOperation* request, id JSON)
    {
        NSLog(@"getPath request: %@", request.request.URL);

        if(JSON && [JSON isKindOfClass:[NSDictionary class]])
        {
            if(success)
            {
                success(request, parameters);
            }
        }
        else
        {
#warning //### Creat correct error domain in Settings.
            NSError*    error = [NSError errorWithDomain:@"com.sample.url.error" code:1 userInfo:nil];
            if(failure)
            {
                failure(request,error);
            }
        }
    }

    failure:failure];
}

@end
