//
//  NumberPayCell.h
//  Talk
//
//  Created by Cornelis van der Bent on 14/07/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@protocol NumberPayCellDelegate <NSObject>

- (void)payNumberForMonths:(int)months;

@end


@interface NumberPayCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIButton*                button1;
@property (nonatomic, weak) IBOutlet UIButton*                button2;
@property (nonatomic, weak) IBOutlet UIButton*                button3;
@property (nonatomic, weak) IBOutlet UIButton*                button4;
@property (nonatomic, weak) IBOutlet UIButton*                button6;
@property (nonatomic, weak) IBOutlet UIButton*                button9;
@property (nonatomic, weak) IBOutlet UIButton*                button12;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activityIndicator1;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activityIndicator2;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activityIndicator3;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activityIndicator4;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activityIndicator6;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activityIndicator9;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activityIndicator12;

@property (nonatomic, weak) id<NumberPayCellDelegate>         delegate;


- (IBAction)payAction:(id)sender;

@end
