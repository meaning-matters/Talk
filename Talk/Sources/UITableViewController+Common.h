//
//  UITableViewController+Common.h
//  Talk
//
//  Created by Cornelis van der Bent on 26/01/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITableViewController (Common)

/**
 *  Makes buttons highlight immediately when touched.
 */
- (void)disableDelayedContentTouches;

@end
