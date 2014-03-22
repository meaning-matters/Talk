//
//  main.m
//  Talk
//
//  Created by Cornelis van der Bent on 28/09/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"


    int main(int argc, char* argv[])
    {
        @autoreleasepool
        {
            // Force use of English.
            [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithObjects:@"en", nil] forKey:@"AppleLanguages"];
            [[NSUserDefaults standardUserDefaults] synchronize];

            return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
        }
    }
