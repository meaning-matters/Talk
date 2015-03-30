//
//  RetryRequest.m
//  Talk
//
//  Created by Dev on 9/3/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import "FailoverWebInterface.h"
#import "RetryRequest.h"


@implementation RetryRequest

- (id)init
{
    if (self = [super init])
    {
        self.startTime = [NSDate date];
    }

    return self;
}


- (void)tryMakeRequest:(AFHTTPRequestOperation*)operation
{
    NSDate*        now     = [[NSDate alloc] init];
    NSTimeInterval elapsed = [now timeIntervalSinceDate:self.startTime];

    if (elapsed > [FailoverWebInterface sharedInterface].timeout)
    {
        operation.responseSerializer = [AFJSONResponseSerializer serializer];
        [[FailoverWebInterface sharedInterface].delegate checkReplyContent:operation.responseObject];
       
        NBLog(@"%@: timeout reached at %@", operation.request.URL, [NSDate new]);
      
        if ([operation isKindOfClass:[FailoverOperation class]])
        {
            FailoverOperation* operationFailure = (FailoverOperation*)operation;

            if (operationFailure.failure)
            {
                operationFailure.failure(operation,operation.error);
            }
        }
        
        return;
    }
    
    [self request:operation];
}


- (void)request:(AFHTTPRequestOperation*)operation
{
    // Get top server and change original URL host
    FailoverWebInterface* interface = [FailoverWebInterface sharedInterface];

    NSURL*    oldUrl = operation.request.URL; //old url - failed
    NSURL*    url    = operation.request.URL; //to be modified
    NSString* server = [interface getServer];

    url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@", oldUrl.scheme, server]];
    
    if (oldUrl.path != nil)
    {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", url.absoluteURL, oldUrl.path]];
    }
    
    if (oldUrl.query != nil)
    {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", url.absoluteURL, oldUrl.query]];
    }

    // Retries the request
    NSURLRequest* request = operation.request;

    // Create a mutable copy of the immutable request and add more headers
    NSMutableURLRequest* mutableRequest = [request mutableCopy];
    [mutableRequest setURL:url];
    request = [mutableRequest copy];
    
    FailoverOperation* operationCopy = [FailoverOperation operationWithOperation:operation request:request];
    
    [operationCopy setCompletionBlockWithSuccess:^(AFHTTPRequestOperation* operation, id responseObject)
    {       
        if ([interface.delegate checkReplyContent:operation.responseObject] == YES)
        {
            [interface reorderServersWithSuccess:YES];
            if ([operation isKindOfClass:[FailoverOperation class]] &&  ((FailoverOperation*)operation).success)
            {
                ((FailoverOperation*)operation).success(operation, responseObject);
            }
        }
        else
        {
            // forced retry
            NBLog(@"error in retry at %@", [NSDate new]);
            [interface reorderServersWithSuccess:NO];
            [self tryMakeRequest:operation];
        }
    }
                                         failure:^(AFHTTPRequestOperation* operation, NSError* error)
    {
        NBLog(@"%@: error in retry at %@", operation.request.URL, [NSDate new]);

        [interface reorderServersWithSuccess:NO];
        [self tryMakeRequest:operation];
    }];

    [interface.operationQueue addOperation:operationCopy];
    //[operationCopy start];
}

@end