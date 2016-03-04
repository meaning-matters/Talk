//
//  BadgeView.m
//  Talk
//
//  Created by Cornelis van der Bent on 04/03/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import "BadgeView.h"
#import "Skinning.h"

const CGFloat kWidth  = 30.0f;
const CGFloat kHeight = 20.0f;


@interface BadgeView ()

@property (nonatomic, strong) UILabel* label;
@property (nonatomic, assign) BOOL     isSettingBackgroundColor;

@end


@implementation BadgeView

@synthesize count = _count;

- (instancetype)init
{
    if (self = [super initWithFrame:CGRectMake(0.0f, 0.0f, kWidth, kHeight)])
    {
        self.isSettingBackgroundColor = YES;
        self.backgroundColor          = [Skinning placeholderColor];
        self.isSettingBackgroundColor = NO;
        self.layer.cornerRadius       = self.frame.size.height / 2.0f;

        self.label = [[UILabel alloc] initWithFrame:self.frame];
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.font          = [UIFont boldSystemFontOfSize:17.0f];
        self.label.textColor     = [UIColor whiteColor];

        [self addSubview:self.label];

        self.count = 0;
    }

    return self;
}


- (void)addToCell:(UITableViewCell*)cell
{
    [cell.contentView addSubview:self];

    self.frame = CGRectMake(241.0f, (cell.contentView.frame.size.height - kHeight) / 2.0f,
                            self.frame.size.width, self.frame.size.height);
}


- (void)setCount:(NSUInteger)count
{
    _count = count;

    self.label.text = [NSString stringWithFormat:@"%d", (int)count];

    self.hidden = (count == 0);
}


// When a UITableViewCell is selected, iOS sets the background color of all subviews.
// To get the desired behaviour (mimicking the iOS' own badge), we need to override.
- (void)setBackgroundColor:(UIColor*)backgroundColor
{
    if (self.isSettingBackgroundColor)
    {
        [super setBackgroundColor:backgroundColor];
    }
    else
    {
        CGFloat white;
        CGFloat alpha;
        [backgroundColor getWhite:&white alpha:&alpha];

        // Turn out that alpha is set to 0.0f when cell is selected,
        // and back to 1.0f again when deselected.
        if (alpha == 0.0f)
        {
            [super setBackgroundColor:[UIColor whiteColor]];
            self.label.textColor = [Skinning tintColor];
        }
        else
        {
            [super setBackgroundColor:backgroundColor];
            self.label.textColor = [UIColor whiteColor];
        }
    }
}

@end
