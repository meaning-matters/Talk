//
//  CallViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 26/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CallOptionsView.h"
#import "CallKeypadView.h"


@interface CallViewController : UIViewController <CallOptionsViewDelegate, CallKeypadViewDelegate>

@property (nonatomic, strong) IBOutlet UIImageView* backgroundImageView;
@property (nonatomic, strong) IBOutlet UIView*      topView;
@property (nonatomic, strong) IBOutlet UIView*      centerRootView;
@property (nonatomic, strong) IBOutlet UIView*      bottomView;

@property (nonatomic, strong) IBOutlet UIImageView* topImageView;
@property (nonatomic, strong) IBOutlet UIImageView* bottomImageView;

@property (nonatomic, strong) IBOutlet UILabel*     infoLabel;
@property (nonatomic, strong) IBOutlet UILabel*     calleeLabel;
@property (nonatomic, strong) IBOutlet UILabel*     dtmfLabel;
@property (nonatomic, strong) IBOutlet UILabel*     statusLabel;

@property (nonatomic, strong) IBOutlet UIButton*    endButton;
@property (nonatomic, strong) IBOutlet UIButton*    hideButton;


- (IBAction)endAction:(id)sender;

- (IBAction)hideAction:(id)sender;

@end
