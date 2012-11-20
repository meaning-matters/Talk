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

@interface DialerViewController : ViewController <KeypadViewDelegate>

@property (nonatomic, readonly) IBOutlet KeypadView*    keypadView;
@property (nonatomic, strong) IBOutlet UILabel*         infoLabel;      // Label above number.
@property (nonatomic, strong) IBOutlet UITextField*     numberField;
@property (nonatomic, strong) IBOutlet UILabel*         nameLabel;      // Label below number.

@end
