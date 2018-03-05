//
//  Application.m
//  Talk
//
//  Created by Cornelis van der Bent on 28/01/2018.
//  Copyright © 2018 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Application.h"

@implementation Application

// Overrides iOS to disable
- (NSString*)preferredContentSizeCategory
{
    return UIContentSizeCategoryExtraLarge;  // UIContentSizeCategoryLarge is iOS' default.
}

@end
