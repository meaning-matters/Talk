//
//  NumberPayCell.m
//  Talk
//
//  Created by Cornelis van der Bent on 14/07/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "NumberPayCell.h"

@implementation NumberPayCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.button1.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.button1.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.button2.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.button2.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.button3.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.button3.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.button4.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.button4.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.button6.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.button6.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.button9.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.button9.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.button12.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.button12.titleLabel.textAlignment = NSTextAlignmentCenter;
}


- (IBAction)payAction:(id)sender
{
    // Because buttons are on table view, they won't highlight (due to 'delayed touches')
    // when touched briefly.  Code below makes sure there's always a short highlight.
    UIButton* button = sender;
    dispatch_async(dispatch_get_main_queue(), ^
    {
        button.highlighted = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
        {
            button.highlighted = NO;

            [self.delegate payNumberForMonths:(int)((UIButton*)sender).tag];
        });
    });
}

@end
