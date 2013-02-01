//
//  BlockAlertView.m
//  Talk
//
//  Created by Cornelis van der Bent on 23/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "BlockAlertView.h"

@interface BlockAlertView ()

@property (nonatomic, copy) void (^completion)(BOOL cancelled, NSInteger buttonIndex);

@end


@implementation BlockAlertView

+ (BlockAlertView*)showAlertViewWithTitle:(NSString*)title
                                  message:(NSString*)message
                               completion:(void (^)(BOOL cancelled, NSInteger buttonIndex))completion
                        cancelButtonTitle:(NSString*)cancelButtonTitle
                        otherButtonTitles:(NSString*)otherButtonTitles, ...
{
    BlockAlertView* alert = [[BlockAlertView alloc] initWithTitle:title
                                                          message:message
                                                        completion:completion
                                                cancelButtonTitle:cancelButtonTitle
                                                otherButtonTitles:otherButtonTitles, nil];

    [alert show];

    return alert;
}


- (BlockAlertView*)initWithTitle:(NSString*)title
                         message:(NSString*)message
                      completion:(void (^)(BOOL cancelled, NSInteger buttonIndex))completion
               cancelButtonTitle:(NSString*)cancelButtonTitle
               otherButtonTitles:(NSString*)otherButtonTitles, ...
{
    self = [super initWithTitle:title
                        message:message
                       delegate:self
              cancelButtonTitle:cancelButtonTitle
              otherButtonTitles:nil];

    if (self)
    {
        _completion = completion;

        va_list titles;
        va_start(titles, otherButtonTitles);

        for (NSString* title = otherButtonTitles; title != nil; title = (__bridge NSString *)va_arg(titles, void *))
        {
            [self addButtonWithTitle:title];
        }
        
        va_end(titles);
    }
    
    return self;
}


- (void)alertView:(UIAlertView*)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (self.completion != nil)
    {
        self.completion(buttonIndex == self.cancelButtonIndex, buttonIndex);
    }
}

@end
