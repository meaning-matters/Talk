//
//  BlockActionSheet.h
//  Talk
//
//  Created by Cornelis van der Bent on 25/01/14.
//  Copyright (c) 2014 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BlockActionSheet : UIActionSheet <UIActionSheetDelegate>

+ (BlockActionSheet*)showActionSheetWithTitle:(NSString*)title
                                   completion:(void (^)(BOOL cancelled, BOOL destruct, NSInteger buttonIndex))completion
                            cancelButtonTitle:(NSString*)cancelButtonTitle
                       destructiveButtonTitle:(NSString*)destructiveButtonTitle
                            otherButtonTitles:(NSString*)otherButtonTitles, ...;

@end
