//
//  NumberBuyCell.m
//  Talk
//
//  Created by Cornelis van der Bent on 14/07/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "NumberBuyCell.h"

@implementation NumberBuyCell

- (IBAction)buyAction:(id)sender
{
    [self.delegate buyNumberForMonths:((UIButton*)sender).tag];
}

@end
