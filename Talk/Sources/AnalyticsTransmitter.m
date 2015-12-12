//
//  AnalyticsTransmitter.m
//  Talk
//
//  Created by Cornelis van der Bent on 10/12/15.
//  Copyright © 2015 NumberBay Ltd. All rights reserved.
//

#import "AnalyticsTransmitter.h"
#import "Settings.h"
#import "NetworkStatus.h"

static NSString* const kServerPath = @"http://trace.numberbay.com/trace";


@implementation AnalyticsTransmitter

+ (AnalyticsTransmitter*)sharedTransmitter
{
    static AnalyticsTransmitter* sharedInstance;
    static dispatch_once_t       onceToken;
    
    dispatch_once(&onceToken, ^
    {
        sharedInstance = [[AnalyticsTransmitter alloc] init];
    });
                  
    return sharedInstance;
}


- (void)sendTraceAtFile:(char*)file line:(int)line value:(NSString*)value
{
    if (self.enabled)
    {
        static int order;
        NSString*  version   = [Settings sharedSettings].appVersion;
        NSUInteger user      = [[Settings sharedSettings].webUsername hash];
        NSString*  fileName  = [[NSString stringWithUTF8String:file] lastPathComponent];
        NSString*  urlString = [NSString stringWithFormat:@"%@?order=%04d&version=%@&user=%016tx&file=%@&line=%d&value=%@",
                                kServerPath, order++, version, user, fileName, line, value];
        
        NBLog(@"TRACE: %@", urlString);
        
        NSURLRequest* request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse* response, NSData* data, NSError* error)
        {
            if (error != nil)
            {
                NBLog(@"Error sending trace: %@.", [error localizedDescription]);
            }
        }];
    }
}

@end
