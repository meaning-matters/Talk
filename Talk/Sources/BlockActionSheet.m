//
//  BlockActionSheet.m
//  Talk
//
//  Created by Cornelis van der Bent on 25/01/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import "BlockActionSheet.h"
#import "AppDelegate.h"


@interface BlockActionSheet ()

@property (nonatomic, copy) void (^completion)(BOOL cancelled, BOOL destruct, NSInteger buttonIndex);

@end


@implementation BlockActionSheet

+ (BlockActionSheet*)showActionSheetWithTitle:(NSString*)title
                                   completion:(void (^)(BOOL cancelled, BOOL destruct, NSInteger buttonIndex))completion
                            cancelButtonTitle:(NSString*)cancelButtonTitle
                       destructiveButtonTitle:(NSString*)destructiveButtonTitle
                            otherButtonTitles:(NSString*)otherButtonTitles, ...
{
    va_list arguments;
    va_start(arguments, otherButtonTitles);

    BlockActionSheet* actionSheet = [[BlockActionSheet alloc] initWithTitle:title
                                                                 completion:completion
                                                          cancelButtonTitle:cancelButtonTitle
                                                     destructiveButtonTitle:destructiveButtonTitle
                                                          otherButtonTitles:otherButtonTitles
                                                                  arguments:arguments];
    [actionSheet showFromTabBar:[AppDelegate appDelegate].tabBarController.tabBar];

    va_end(arguments);

    return actionSheet;
}


- (BlockActionSheet*)initWithTitle:(NSString*)title
                        completion:(void (^)(BOOL cancelled, BOOL destruct, NSInteger buttonIndex))completion
                 cancelButtonTitle:(NSString*)cancelButtonTitle
            destructiveButtonTitle:(NSString*)destructiveButtonTitle
                 otherButtonTitles:(NSString*)otherButtonTitles
                         arguments:(va_list)arguments
{
    self = [super initWithTitle:title
                       delegate:self
              cancelButtonTitle:cancelButtonTitle
         destructiveButtonTitle:destructiveButtonTitle
              otherButtonTitles:nil];

    if (self)
    {
        _completion = completion;

        for (NSString* title = otherButtonTitles; title != nil; title = (__bridge NSString*)va_arg(arguments, void*))
        {
            [self addButtonWithTitle:title];
        }
    }

    return self;
}


#pragma Action Sheet Delegate

- (void)actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    self.completion ? self.completion(buttonIndex == actionSheet.cancelButtonIndex,
                                      buttonIndex == actionSheet.destructiveButtonIndex,
                                      buttonIndex) : 0;
}

@end
