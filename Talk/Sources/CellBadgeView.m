//
//  CellBadgeView.m
//  Talk
//
//  Created by Cornelis van der Bent on 04/03/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import "CellBadgeView.h"
#import "Skinning.h"

const CGFloat   CellBadgeWidth   =  30.0f;
const CGFloat   CellBadgeHeight  =  20.0f;
const CGFloat   CellBadgeXOffset = 255.0f;
const NSInteger CellBadgeTag     = 777;


@interface CellBadgeView ()

@property (nonatomic, strong) UILabel* label;
@property (nonatomic, assign) BOOL     isSettingBackgroundColor;

@end


@implementation CellBadgeView

@synthesize count = _count;

- (instancetype)init
{
    if (self = [super initWithFrame:CGRectMake(0.0f, 0.0f, CellBadgeWidth, CellBadgeHeight)])
    {
        self.tag = CellBadgeTag;

        self.isSettingBackgroundColor = YES;
        self.backgroundColor          = [Skinning cellBadgeColor];
        self.isSettingBackgroundColor = NO;
        self.layer.cornerRadius       = CellBadgeHeight / 2.0f;
        self.userInteractionEnabled   = NO;  // Let touch events through to tab bar

        self.label = [[UILabel alloc] initWithFrame:self.bounds];
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.font          = [UIFont boldSystemFontOfSize:17.0f];
        self.label.textColor     = [UIColor whiteColor];
        self.label.lineBreakMode = NSLineBreakByTruncatingTail;

        [self addSubview:self.label];

        self.count = 0;
    }

    return self;
}


+ (void)addToCell:(UITableViewCell*)cell count:(NSUInteger)count
{
    CellBadgeView* badgeView = [CellBadgeView getFromCell:cell];

    if (badgeView == nil)
    {
        badgeView = [[CellBadgeView alloc] init];
        badgeView.frame = CGRectMake(CellBadgeXOffset, (cell.contentView.frame.size.height - CellBadgeHeight) / 2.0f,
                                     CellBadgeWidth, CellBadgeHeight);
        [cell.contentView addSubview:badgeView];
    }

    [cell.contentView bringSubviewToFront:badgeView];

    badgeView.count = count;
}


+ (CellBadgeView*)getFromCell:(UITableViewCell*)cell
{
    CellBadgeView* subview = [cell.contentView viewWithTag:CellBadgeTag];

    return [subview isKindOfClass:[self class]] ? subview : nil;
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
