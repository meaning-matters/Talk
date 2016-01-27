//
//  NumberBuyCell.h
//  Talk
//
//  Created by Cornelis van der Bent on 14/07/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@protocol NumberBuyCellDelegate <NSObject>

- (void)buyNumber;

@end


@interface NumberBuyCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIButton*                button;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activityIndicator;

@property (nonatomic, weak) id<NumberBuyCellDelegate>         delegate;

@end
