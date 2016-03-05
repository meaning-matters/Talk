//
//  DotView.m
//  Talk
//
//  Created by Cornelis van der Bent on 04/03/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import "DotView.h"
#import "Skinning.h"

const CGFloat kDiameter = 6.0f;


@interface DotView ()

@property (nonatomic, assign) BOOL isSettingBackgroundColor;

@end


@implementation DotView

- (instancetype)init
{
    if (self = [super initWithFrame:CGRectMake(0.0f, 0.0f, kDiameter, kDiameter)])
    {
        self.isSettingBackgroundColor = YES;
        self.backgroundColor    = [Skinning tintColor];
        self.isSettingBackgroundColor = NO;
        self.layer.cornerRadius = self.frame.size.height / 2.0f;
    }

    return self;
}


- (void)addToCell:(UITableViewCell*)cell
{
    [cell.contentView addSubview:self];

    self.frame = CGRectMake(5.0f, (cell.contentView.frame.size.height - kDiameter) / 2.0f,
                            self.frame.size.width, self.frame.size.height);
}


+ (DotView*)getFromCell:(UITableViewCell*)cell
{
    DotView* subview = [cell.contentView.subviews firstObject];

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
