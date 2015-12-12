//
//  AnalyticsTransmitter.h
//  Talk
//
//  Created by Cornelis van der Bent on 10/12/15.
//  Copyright © 2015 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AnalyticsTransmitter;

#define AnalysticsTrace(v) [[AnalyticsTransmitter sharedTransmitter] sendTraceAtFile:__FILE__ line:__LINE__ value:(v)];


@interface AnalyticsTransmitter : NSObject

@property (nonatomic, assign) BOOL enabled;


+ (AnalyticsTransmitter*)sharedTransmitter;

- (void)sendTraceAtFile:(char*)file line:(int)line value:(NSString*)v;

@end
