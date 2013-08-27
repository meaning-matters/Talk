//
//  CreditBuyCell.h
//  Talk
//
//  Created by Cornelis van der Bent on 25/08/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CreditBuyCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView*             amountImageView;
@property (nonatomic, weak) IBOutlet UILabel*                 descriptionLabel;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activityIndicator;

@end
