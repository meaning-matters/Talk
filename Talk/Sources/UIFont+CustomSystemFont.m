//
//  UIFont+CustomSystemFont.m
//  Talk
//
//  Created by Cornelis van der Bent on 20/12/2017.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

// https://stackoverflow.com/questions/22085059/what-method-do-you-call-to-get-the-users-preferred-text-size

#import <objc/runtime.h>
#import "UIFont+CustomSystemFont.h"

@implementation UIFont (CustomSystemFont)

+ (UIFont*)modified_systemFontOfSize:(CGFloat)size
{
    return [UIFont fontWithName:@"Courier" size:10];
}

+ (UIFont*)modified_boldSystemFontOfSize:(CGFloat)size
{
    return [UIFont fontWithName:@"Courier" size:10];
}

+ (UIFont*)modified_preferredFontForTextStyle:(UIFontTextStyle)style
{
    NSLog(@"<<<<<<< %@", style);

    return [UIFont fontWithName:@"Courier" size:10];
}

+ (CGFloat)labelFontSize
{
    return 10;
}

+ (CGFloat)buttonFontSize
{
    return 10;
}

+ (CGFloat)smallSystemFontSize
{
    return 10;
}

+ (CGFloat)systemFontSize
{
    return 10;
}

+ (void)load
{
    SEL original = @selector(systemFontOfSize:);
    SEL modified = @selector(modified_systemFontOfSize:);
    Method originalMethod = class_getClassMethod(self, original);
    Method modifiedMethod = class_getClassMethod(self, modified);
    method_exchangeImplementations(originalMethod, modifiedMethod);

    SEL originalBold = @selector(boldSystemFontOfSize:);
    SEL modifiedBold = @selector(modified_boldSystemFontOfSize:);
    Method originalBoldMethod = class_getClassMethod(self, originalBold);
    Method modifiedBoldMethod = class_getClassMethod(self, modifiedBold);
    method_exchangeImplementations(originalBoldMethod, modifiedBoldMethod);

    SEL originalPreferred = @selector(preferredFontForTextStyle:);
    SEL modifiedPreferred = @selector(modified_preferredFontForTextStyle:);
    Method originalPreferredMethod = class_getClassMethod(self, originalPreferred);
    Method modifiedPreferredMethod = class_getClassMethod(self, modifiedPreferred);
    method_exchangeImplementations(originalPreferredMethod, modifiedPreferredMethod);
}

@end
