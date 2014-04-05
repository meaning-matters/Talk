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
    static Skinning*       sharedInstance;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^
    {
        sharedInstance = [[Skinning alloc] init];
        [sharedInstance update];

        [[Settings sharedSettings] addObserver:sharedInstance
                                    forKeyPath:@"callbackMode"
                                       options:0
                                       context:nil];
        
        [UIApplication sharedApplication].keyWindow.tintColor = [self tintColor];
    });
    
    return sharedInstance;
}


+ (UIColor*)callbackModeTintColor
{
    return [UIColor colorWithHue:0.40f saturation:0.90f brightness:0.85f alpha:1.00f];
}


+ (UIColor*)tintColor
{
    return [UIColor colorWithRed:0.26f green:0.41f blue:1.00f alpha:1.00f]; // NumberBay blue.
}


+ (UIColor*)onTintColor
{
    return [UIColor colorWithRed:0.344f green:0.845f blue:0.515f alpha:1.0f];
}


+ (UIColor*)deleteTintColor
{
    return [UIColor colorWithRed:0.988f green:0.082f blue:0.275f alpha:1.0f];
}


- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    [self update];
}


- (void)update
{
    if ([Settings sharedSettings].callbackMode == NO || HAS_VOIP == NO)
    {
        [[AppDelegate appDelegate].tabBarController.tabBar setSelectedImageTintColor:nil];
    }
    else
    {
        [[AppDelegate appDelegate].tabBarController.tabBar setSelectedImageTintColor:[Skinning callbackModeTintColor]];
    }
}

@end
