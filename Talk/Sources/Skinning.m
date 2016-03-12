//
//  Skinning.m
//  Talk
//
//  Created by Cornelis van der Bent on 07/11/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
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

        [UIApplication sharedApplication].keyWindow.tintColor = [self tintColor];
    });
    
    return sharedInstance;
}


+ (UIColor*)tintColor
{
    return [UIColor colorWithRed:0.26f green:0.41f blue:1.00f alpha:1.00f]; // NumberBay blue.
}


+ (UIColor*)onTintColor
{
    return [UIColor colorWithRed:0.344f green:0.845f blue:0.515f alpha:1.0f]; // Green
}


+ (UIColor*)deleteTintColor
{
    return [UIColor colorWithRed:0.988f green:0.082f blue:0.275f alpha:1.0f];
}


+ (UIColor*)backgroundTintColor
{
    return [UIColor colorWithRed:0.935 green:0.937 blue:0.958 alpha:1.0f];  // Color seen on grouped table views.
}


+ (UIColor*)placeholderColor
{
    return [UIColor colorWithRed:0.78f green:0.78f blue:0.80f alpha:1.00f];
}


+ (UIColor*)valueColor
{
    return [UIColor colorWithWhite:0.55f alpha:1.00f];
}


+ (UIColor*)contactRateColor
{
    return [UIColor colorWithRed:0.78f green:0.78f blue:0.80f alpha:1.00f];
}


+ (UIColor*)tabBadgeColor
{
    return [self deleteTintColor];
}


+ (UIColor*)cellBadgeColor
{
    return [UIColor colorWithRed:0.67f green:0.67f blue:0.68f alpha:1.00f];
}

@end
