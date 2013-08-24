//
//  BuyNumberCell.h
//  Talk
//
//  Created by Cornelis van der Bent on 14/07/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BuyNumberCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView*             durationImageView;
@property (nonatomic, weak) IBOutlet UILabel*                 monthsLabel;
@property (nonatomic, weak) IBOutlet UILabel*                 setupLabel;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activityIndicator;

@end
