//
//  UIViewController+Common.h
//  Talk
//
//  Created by Cornelis van der Bent on 04/01/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface UIViewController (Common)

@property (nonatomic, strong) UIActivityIndicatorView* activityIndicator;
@property (nonatomic, strong) UIImageView*             imageView;
@property (nonatomic, assign) BOOL                     hasCenteredActivityIndicator;
@property (nonatomic, assign) BOOL                     isLoading;   // Show/Hide spinner.

@end
