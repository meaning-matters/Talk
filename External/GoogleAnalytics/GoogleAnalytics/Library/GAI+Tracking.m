//
//  GAI+Tracking.m
//  Talk
//
//  Created by Cornelis van der Bent on 17/12/17.
//  Copyright (c) 1017 NumberBay Ltd. All rights reserved.
//

#import "GAI+Tracking.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"

@implementation GAI (Tracking)

- (void)trackScreenWithName:(NSString*)screenName
{
    [self.defaultTracker set:kGAIScreenName value:screenName];
    [self.defaultTracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

@end
