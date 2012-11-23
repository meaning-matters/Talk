//
//  BlockAlertView.h
//  Talk
//
//  Created by Cornelis van der Bent on 23/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BlockAlertView : UIAlertView <UIAlertViewDelegate>

+ (UIAlertView*)showAlertViewWithTitle:(NSString*)title
                               message:(NSString*)message
                            completion:(void (^)(BOOL cancelled, NSInteger buttonIndex))completion
                     cancelButtonTitle:(NSString*)cancelButtonTitle
                     otherButtonTitles:(NSString*)otherButtonTitles, ...;

@end
