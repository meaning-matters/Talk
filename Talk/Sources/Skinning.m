//
//  Skinning.m
//  Talk
//
//  Created by Cornelis van der Bent on 07/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "Skinning.h"

@implementation Skinning

static Skinning*    sharedSkinning;


#pragma mark - Singleton Stuff

+ (void)initialize
{
    if ([Skinning class] == self)
    {
        sharedSkinning = [self new];
        [Skinning setUp];
    }
}


+ (id)allocWithZone:(NSZone*)zone
{
    if (sharedSkinning && [Skinning class] == self)
    {
        [NSException raise:NSGenericException format:@"Duplicate Skinning singleton creation"];
    }

    return [super allocWithZone:zone];
}


+ (Skinning*)sharedSkinning
{
    return sharedSkinning;
}


+ (void)setUp
{
    // Place app-wide skinning/appearance commands here.
    [[UINavigationBar appearance] setBarStyle:UIBarStyleBlackOpaque];
}

@end
