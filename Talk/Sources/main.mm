//
//  main.mm
//  Talk
//
//  Created by Cornelis van der Bent on 28/09/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"


int main(int argc, char* argv[])
{
    @autoreleasepool
    {
        // Force use of English.  (When changed check CountryNames.m and other locale dependencies.)
        [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithObject:@"en"] forKey:@"AppleLanguages"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
