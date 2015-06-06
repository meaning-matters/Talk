//
//  CreditBuyCell.m
//  Talk
//
//  Created by Cornelis van der Bent on 25/08/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "CreditBuyCell.h"


@implementation CreditBuyCell

- (IBAction)buyAction:(id)sender
{
    [self.delegate buyCreditForTier:(int)((UIButton*)sender).tag];
}

@end
