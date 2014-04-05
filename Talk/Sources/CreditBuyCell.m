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
    self.buyButton = sender;
    [self.delegate buyCreditForTier:self.buyButton.tag];
}

@end
