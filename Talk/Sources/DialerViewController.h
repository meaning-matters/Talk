//
//  DialerViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"
#import "KeypadView.h"
#import "PhoneNumber.h"
#import "NumberLabel.h"


@interface DialerViewController : ViewController <KeypadViewDelegate, NumberLabelDelegate>

@property (nonatomic, strong, readonly) IBOutlet KeypadView*    keypadView;
@property (nonatomic, strong) IBOutlet UILabel*                 infoLabel;      // Label above number.
@property (nonatomic, strong) IBOutlet NumberLabel*             numberLabel;
@property (nonatomic, strong) IBOutlet UILabel*                 nameLabel;      // Label below number.

@end
