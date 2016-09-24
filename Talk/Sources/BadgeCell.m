//
//  BadgeCell.m
//  Talk
//
//  Created by Cornelis van der Bent on 24/09/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import "BadgeCell.h"
#import "CellBadgeView.h"

@implementation BadgeCell

- (void)setBadgeCount:(NSUInteger)badgeCount
{
    _badgeCount = badgeCount;

    [CellBadgeView addToCell:self count:badgeCount];

    [self setNeedsLayout];// Needed?
}


- (void)layoutSubviews
{
    [super layoutSubviews];

    CGSize  size   = self.textLabel.frame.size;
    CGPoint origin = self.textLabel.frame.origin;
    CGFloat width  = self.frame.size.width - origin.x - ((self.badgeCount > 0) ? 68.0f : 36.0f);

    self.textLabel.frame = CGRectMake(origin.x, origin.y, width, size.height);
}

@end
