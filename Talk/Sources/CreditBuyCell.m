//
//  CreditBuyCell.m
//  Talk
//
//  Created by Cornelis van der Bent on 25/08/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "CreditBuyCell.h"


@implementation CreditBuyCell

- (IBAction)buyAction:(id)sender
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

            [self.delegate buyCreditAmount:(int)((UIButton*)sender).tag];
        });
    });
}

@end
