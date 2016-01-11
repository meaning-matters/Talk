//
//  CreditAmountCell.h
//  Talk
//
//  Created by Cornelis van der Bent on 26/08/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface CreditAmountCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel*                 amountLabel;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activityIndicator;
@property (nonatomic, weak) IBOutlet UILabel*                 noteLabel;

@end
