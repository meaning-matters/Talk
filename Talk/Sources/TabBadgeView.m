//
//  TabBadgeView.m
//  Talk
//
//  Created by Cornelis van der Bent on 11/03/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import "TabBadgeView.h"
#import "Skinning.h"
#import "AppDelegate.h"

const CGFloat BadgeHeight       = 18.5f;
const CGFloat BadgeWidthMaximum = 40.0f;


@interface TabBadgeView ()

@property (nonatomic, strong) UILabel* label;

@end


@implementation TabBadgeView

@synthesize count = _count;

- (instancetype)init
{
    if (self = [super initWithFrame:CGRectMake(0.0f, 0.0f, BadgeHeight, BadgeHeight)])
    {
        self.backgroundColor        = [Skinning tabBadgeColor];
        self.layer.cornerRadius     = BadgeHeight / 2.0f;
        self.userInteractionEnabled = NO;   // Let touch events through to tab bar.

        self.label = [[UILabel alloc] initWithFrame:self.bounds];
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.font          = [UIFont systemFontOfSize:13.0f];
        self.label.textColor     = [UIColor whiteColor];
        self.label.lineBreakMode = NSLineBreakByTruncatingTail;

        [self addSubview:self.label];

        self.count = 0;
    }

    return self;
}


- (void)setCount:(NSUInteger)count
{
    _count = count;

    self.label.text = [NSString stringWithFormat:@"%d", (int)count];

    CGFloat right = self.frame.origin.x + self.frame.size.width;
    CGRect  frame = self.frame;

    frame.size.width = MAX(MIN(BadgeWidthMaximum, self.label.intrinsicContentSize.width + 10), BadgeHeight);
    frame.origin.x   = right - frame.size.width;

    self.frame       = frame;
    self.label.frame = self.bounds;

    self.hidden = (count == 0);
}

@end
