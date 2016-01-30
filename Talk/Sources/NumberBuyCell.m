//
//  NumberBuyCell.m
//  Talk
//
//  Created by Cornelis van der Bent on 14/07/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "NumberBuyCell.h"

@implementation NumberBuyCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.button.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.button.titleLabel.textAlignment = NSTextAlignmentCenter;
}


- (IBAction)buyAction:(id)sender
{
    [self.delegate buyNumberAction];
}

@end
