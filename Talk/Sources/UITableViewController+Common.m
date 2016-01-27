//
//  UITableViewController+Common.m
//  Talk
//
//  Created by Cornelis van der Bent on 26/01/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import "UITableViewController+Common.h"

@implementation UITableViewController (Common)

- (void)disableDelayedContentTouches
{
    // Make buttons highlight immediately http://stackoverflow.com/a/27417587/1971013
    self.tableView.delaysContentTouches = NO;
    for (id view in self.tableView.subviews)
    {
        if ([NSStringFromClass([view class]) isEqualToString:@"UITableViewWrapperView"])
        {
            if ([view isKindOfClass:[UIScrollView class]])
            {
                [view setDelaysContentTouches:NO];
            }

            break;
        }
    }
}

@end
