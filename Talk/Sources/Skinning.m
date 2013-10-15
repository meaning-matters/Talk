//
//  Skinning.m
//  Talk
//
//  Created by Cornelis van der Bent on 07/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "Skinning.h"
#import "AppDelegate.h"
#import "Settings.h"


@implementation Skinning

#pragma mark - Singleton Stuff

+ (Skinning*)sharedSkinning
{
    static Skinning*        sharedInstance;
    static dispatch_once_t  onceToken;
    
    dispatch_once(&onceToken, ^
    {
        sharedInstance = [[Skinning alloc] init];
        [sharedInstance update];

        [[Settings sharedSettings] addObserver:sharedInstance
                                    forKeyPath:@"callbackMode"
                                       options:NSKeyValueChangeOldKey
                                       context:nil];
    });
    
    return sharedInstance;
}


+ (UIColor*)callbackModeTintColor
{
    return [UIColor colorWithHue:0.4 saturation:0.9 brightness:0.85 alpha:1.0];
}


- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    [self update];
}


- (void)update
{
    if ([Settings sharedSettings].callbackMode == NO)
    {
        [[AppDelegate appDelegate].tabBarController.tabBar setSelectedImageTintColor:nil];
    }
    else
    {
        [[AppDelegate appDelegate].tabBarController.tabBar setSelectedImageTintColor:[Skinning callbackModeTintColor]];
    }

    [[UINavigationBar appearance] setBarStyle:UIBarStyleBlackOpaque];
}

@end
