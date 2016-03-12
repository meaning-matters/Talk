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

const CGFloat kHeight       = 18.5f;
const CGFloat kWidthMaximum = 40.0f;


@interface TabBadgeView ()

@property (nonatomic, strong) UILabel* label;

@end


@implementation TabBadgeView

@synthesize count = _count;

- (instancetype)init
{
    if (self = [super initWithFrame:CGRectMake(0.0f, 0.0f, kHeight, kHeight)])
    {
        self.backgroundColor        = [Skinning tabBadgeColor];
        self.layer.cornerRadius     = kHeight / 2.0f;
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

    CGRect frame = self.frame;
    frame.size.width = MAX(MIN(kWidthMaximum, self.label.intrinsicContentSize.width + 10), kHeight);
    frame.origin.x  -= frame.size.width - kHeight;
    self.frame       = frame;
    self.label.frame = self.bounds;

    self.hidden = (count == 0);
}

@end
