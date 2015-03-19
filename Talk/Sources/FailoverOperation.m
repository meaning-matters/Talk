//
//  AFHTTPRequestOperationFailover.m
//  Talk
//
//  Created by Dev on 9/10/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import "FailoverOperation.h"
#import "FailoverWebInterface.h"


@implementation FailoverOperation


+ (instancetype)operationWithOperation:(AFHTTPRequestOperation*)operation request:(NSURLRequest*)request
{
    FailoverOperation* operationFailover = [[FailoverOperation alloc] initWithRequest:request];
    
    operationFailover.responseSerializer         = operation.responseSerializer;
    operationFailover.shouldUseCredentialStorage = operation.shouldUseCredentialStorage;
    operationFailover.credential                 = operation.credential;
    operationFailover.securityPolicy             = operation.securityPolicy;
    operationFailover.completionQueue            = operation.completionQueue;
    operationFailover.completionGroup            = operation.completionGroup;
    
    if ([operation isKindOfClass:[FailoverOperation class]])
    {
        FailoverOperation* operationFailure = (FailoverOperation*)operation;
        operationFailover.success = operationFailure.success;
        operationFailover.failure = operationFailure.failure;
    }
    
    return operationFailover;
}


// Early error detection. No need to wait for notification event
- (void)connectionDidFinishLoading:(__unused NSURLConnection*)connection
{
    NSHTTPURLResponse* httpResponse = self.response;
    if (httpResponse.statusCode / 100 == 2) // failure considered, so start the retry algorithm
    {
        NSDictionary* headers = [(NSURLRequest*)self.request allHTTPHeaderFields];

        if ([FailoverOperation hasIgnoreStartHeader:headers])
        {
            [super connectionDidFinishLoading:connection];
        }
        else
        {
            [[FailoverWebInterface sharedInterface] networkRequestFail:self];
        }
    }
    else
    {
        [super connectionDidFinishLoading:connection];
    }
}


+ (BOOL)hasIgnoreStartHeader:(NSDictionary*)dictionary
{
    for (NSString* key in dictionary.keyEnumerator)
    {
        if ([key isEqualToString:@"IgnoreClientStartRetry"])
        {
            return true;
        }
    }

    return false;
}

@end


