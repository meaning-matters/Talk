//
//  CallbackViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 09/10/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Call.h"


@interface CallbackViewController : UIViewController

@property (nonatomic, strong) Call*                 call;

@property (nonatomic, weak) IBOutlet UIImageView*   backgroundImageView;
@property (nonatomic, weak) IBOutlet UIView*        topView;
@property (nonatomic, weak) IBOutlet UIView*        centerRootView;
@property (nonatomic, weak) IBOutlet UIView*        bottomView;

@property (nonatomic, weak) IBOutlet UIImageView*   topImageView;
@property (nonatomic, weak) IBOutlet UIImageView*   bottomImageView;

@property (nonatomic, weak) IBOutlet UILabel*       infoLabel;
@property (nonatomic, weak) IBOutlet UILabel*       calleeLabel;
@property (nonatomic, weak) IBOutlet UILabel*       statusLabel;

@property (nonatomic, weak) IBOutlet UIButton*      endButton;


- (id)initWithCall:(Call*)call;

- (IBAction)endAction:(id)sender;

@end
