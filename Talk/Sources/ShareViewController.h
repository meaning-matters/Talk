//
//  ShareViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"

@interface ShareViewController : ViewController

@property (nonatomic, weak) IBOutlet UIButton*  twitterButton;
@property (nonatomic, weak) IBOutlet UIButton*  facebookButton;
@property (nonatomic, weak) IBOutlet UIButton*  smsButton;
@property (nonatomic, weak) IBOutlet UIButton*  emailButton;
@property (nonatomic, weak) IBOutlet UIButton*  rateButton;

@end
