//
//  UIViewController+Common.h
//  Talk
//
//  Created by Cornelis van der Bent on 04/01/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface UIViewController (Common) <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIActivityIndicatorView* activityIndicator;
@property (nonatomic, strong) UIImageView*             imageView;
@property (nonatomic, assign) BOOL                     hasCenteredActivityIndicator;
@property (nonatomic, assign) BOOL                     isLoading;   // Show/Hide spinner.

@property (nonatomic, assign) BOOL                     showFootnotes;

// Only used internally properties (can't be placed in .m file).
@property (nonatomic, assign) BOOL                     settingsShowFootnotes;
@property (nonatomic, strong) UITableView*             localTableView;
@property (nonatomic, strong) id<NSObject>             defaultsObserver;

- (void)updateAllSectionsOfTableView:(UITableView*)tableView;

- (void)setupFootnotesHandlingOnTableView:(UITableView*)tableView;

@end
