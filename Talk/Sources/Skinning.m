//
//  Skinning.m
//  Talk
//
//  Created by Cornelis van der Bent on 07/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "Skinning.h"

@implementation Skinning

#pragma mark - Singleton Stuff

+ (Skinning*)sharedSkinning
{
    static Skinning*        sharedInstance;
    static dispatch_once_t  onceToken;
    
    dispatch_once(&onceToken, ^
    {
        sharedInstance = [[Skinning alloc] init];

        // Place app-wide skinning/appearance commands here.
        [[UINavigationBar appearance] setBarStyle:UIBarStyleBlackOpaque];
    });
    
    return sharedInstance;
}

@end
