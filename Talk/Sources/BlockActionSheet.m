//
//  BlockActionSheet.m
//  Talk
//
//  Created by Cornelis van der Bent on 25/01/14.
//  Copyright (c) 2014 NumberBay Ltd. All rights reserved.
//

#import "BlockActionSheet.h"
#import "AppDelegate.h"
#import "Skinning.h"


@interface BlockActionSheet ()

@property (nonatomic, copy) void (^completion)(BOOL cancelled, BOOL destruct, NSInteger buttonIndex);
@property (nonatomic, assign) NSInteger otherNumberOfButtons;

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
              cancelButtonTitle:nil
         destructiveButtonTitle:nil
              otherButtonTitles:nil];

    if (self)
    {
        _completion = completion;

        if (destructiveButtonTitle != nil)
        {
            NSInteger index = [self addButtonWithTitle:destructiveButtonTitle];
            self.destructiveButtonIndex = index;
        }

        for (NSString* title = otherButtonTitles; title != nil; title = (__bridge NSString*)va_arg(arguments, void*))
        {
            [self addButtonWithTitle:title];
            self.otherNumberOfButtons++;
        }

        if (cancelButtonTitle != nil)
        {
            NSInteger index = [self addButtonWithTitle:cancelButtonTitle];
            self.cancelButtonIndex = index;
        }
    }

    return self;
}


#pragma Action Sheet Delegate

- (void)willPresentActionSheet:(UIActionSheet*)actionSheet
{
    NSInteger index       = 0;
    UIColor*  deleteColor = [[NBAddressBookManager sharedManager].delegate deleteTintColor];
    UIColor*  tintColor   = [[NBAddressBookManager sharedManager].delegate tintColor];
    for (UIView* subview in actionSheet.subviews)
    {
        if ([subview isKindOfClass:[UIButton class]])
        {
            UIButton* button = (UIButton*)subview;
            UIColor*  color  = (index == self.destructiveButtonIndex) ? deleteColor : tintColor;

            [button setTitleColor:color forState:UIControlStateHighlighted];
            [button setTitleColor:color forState:UIControlStateNormal];
            [button setTitleColor:color forState:UIControlStateSelected];

            index++;
        }
    }
}


- (void)actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    self.completion ? self.completion(buttonIndex == actionSheet.cancelButtonIndex,
                                      buttonIndex == actionSheet.destructiveButtonIndex,
                                      buttonIndex) : 0;
}

@end
