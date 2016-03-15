//
//  CellDotView.m
//  Talk
//
//  Created by Cornelis van der Bent on 04/03/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import "CellDotView.h"
#import "Skinning.h"

const CGFloat   kDiameter       = 10.0f;
const NSInteger kCellDotViewTag = 123;


@interface CellDotView ()

@property (nonatomic, assign) BOOL isSettingBackgroundColor;

@end


@implementation CellDotView

- (instancetype)init
{
    if (self = [super initWithFrame:CGRectMake(0.0f, 0.0f, kDiameter, kDiameter)])
    {
        self.tag = kCellDotViewTag;

        self.isSettingBackgroundColor = YES;
        self.backgroundColor          = [Skinning cellBadgeColor];
        self.isSettingBackgroundColor = NO;
        self.layer.cornerRadius       = self.frame.size.height / 2.0f;
    }

    return self;
}


- (void)addToCell:(UITableViewCell*)cell
{
    [cell.contentView addSubview:self];

    self.frame = CGRectMake(3.0f, (cell.contentView.frame.size.height - kDiameter) / 2.0f,
                            self.frame.size.width, self.frame.size.height);
}


+ (CellDotView*)getFromCell:(UITableViewCell*)cell
{
    CellDotView* subview = [cell.contentView viewWithTag:kCellDotViewTag];

    return [subview isKindOfClass:[self class]] ? subview : nil;
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
        // We get here when iOS tries to set the background color.  We don't want any color change.
    }
}

@end
