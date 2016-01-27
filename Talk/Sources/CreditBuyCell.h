//
//  CreditBuyCell.h
//  Talk
//
//  Created by Cornelis van der Bent on 25/08/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@protocol CreditBuyCellDelegate <NSObject>

- (void)buyCreditForTier:(int)tier;

@end


@interface CreditBuyCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIButton*                button1;
@property (nonatomic, weak) IBOutlet UIButton*                button2;
@property (nonatomic, weak) IBOutlet UIButton*                button5;
@property (nonatomic, weak) IBOutlet UIButton*                button10;
@property (nonatomic, weak) IBOutlet UIButton*                button20;
@property (nonatomic, weak) IBOutlet UIButton*                button50;
@property (nonatomic, weak) IBOutlet UIButton*                button100;
@property (nonatomic, weak) IBOutlet UIButton*                button200;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activityIndicator1;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activityIndicator2;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activityIndicator5;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activityIndicator10;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activityIndicator20;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activityIndicator50;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activityIndicator100;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activityIndicator200;

@property (nonatomic, weak) id<CreditBuyCellDelegate>         delegate;


- (IBAction)buyAction:(id)sender;

@end
