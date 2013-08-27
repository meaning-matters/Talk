//
//  CreditAmountCell.h
//  Talk
//
//  Created by Cornelis van der Bent on 26/08/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CreditAmountCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel*                 amountLabel;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activityIndicator;

@end
