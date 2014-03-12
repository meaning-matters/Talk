//
//  DialerViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KeypadView.h"
#import "PhoneNumber.h"
#import "NumberLabel.h"


@interface DialerViewController : UIViewController <KeypadViewDelegate>

@property (nonatomic, weak) IBOutlet UIImageView*           brandingImageView;
@property (nonatomic, weak) IBOutlet UILabel*               infoLabel;      // Label above number.
@property (nonatomic, weak) IBOutlet NumberLabel*           numberLabel;
@property (nonatomic, weak) IBOutlet UILabel*               nameLabel;      // Label below number.
@property (nonatomic, weak, readonly) IBOutlet KeypadView*  keypadView;

@end
