//
//  CellBadgeView.h
//  Talk
//
//  Created by Cornelis van der Bent on 04/03/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CellBadgeView : UIView

@property (nonatomic, assign) NSUInteger count;

/**
 *  Adds a badge to a cell. Removing a badge done by calling this method with a `count` of `0`.
 *
 *  @param cell  The cell to add/remove a badge.
 *  @param count The badge count, or remove badge if `0`.
 */
+ (void)addToCell:(UITableViewCell*)cell count:(NSUInteger)count;

@end
