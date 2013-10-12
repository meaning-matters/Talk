//
//  CallBaseViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 12/10/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Call.h"


const NSTimeInterval    TransitionDuration = 0.5;


@interface CallBaseViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIImageView*   backgroundImageView;
@property (nonatomic, weak) IBOutlet UIView*        topView;
@property (nonatomic, weak) IBOutlet UIView*        centerRootView;
@property (nonatomic, weak) IBOutlet UIView*        bottomView;

@property (nonatomic, weak) IBOutlet UIImageView*   topImageView;
@property (nonatomic, weak) IBOutlet UIImageView*   bottomImageView;

@property (nonatomic, weak) IBOutlet UILabel*       infoLabel;
@property (nonatomic, weak) IBOutlet UILabel*       calleeLabel;
@property (nonatomic, weak) IBOutlet UILabel*       dtmfLabel;
@property (nonatomic, weak) IBOutlet UILabel*       statusLabel;

@property (nonatomic, weak) IBOutlet UIButton*      endButton;
@property (nonatomic, weak) IBOutlet UIButton*      hideButton;
@property (nonatomic, weak) IBOutlet UIButton*      retryButton;


- (IBAction)endAction:(id)sender;

- (IBAction)hideAction:(id)sender;

- (IBAction)retryAction:(id)sender;


- (void)animateView:(UIView*)view fromHidden:(BOOL)fromHide toHidden:(BOOL)toHide;

- (void)showLargeEndButton;

- (void)showSmallEndButton;

- (void)showEndButtonWithWidth:(CGFloat)width imageName:(NSString*)imageName;

- (void)drawTopImage;

- (void)drawBottomImage;

- (void)drawEndButton;

- (void)drawHideButton;

- (void)drawRetryButton;


@end
