//
//  NavigationController.m
//  Talk
//
//  Created by Cornelis van der Bent on 14/05/14.
//  Copyright (c) 2014 NumberBay Ltd. All rights reserved.
//
//  This class is needed to work around a nasty iOS bug: http://stackoverflow.com/a/23666520/1971013

#import "NavigationController.h"


@implementation NavigationController

- (instancetype)initWithRootViewController:(UIViewController*)rootViewController
{
    if (self = [super initWithRootViewController:rootViewController])
    {
        NSString* className = NSStringFromClass([rootViewController class]);
        NSString* name      = [className stringByReplacingOccurrencesOfString:@"ViewController" withString:@""];

        self.tabBarItem.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@Tab.png", name]];
    }

    return self;
}

@end
