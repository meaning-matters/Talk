//
//  CallbackViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 09/10/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CallBaseViewController.h"
#import "Call.h"


@interface CallbackViewController : CallBaseViewController

@property (nonatomic, strong) Call* call;

- (instancetype)initWithCall:(Call*)call;

@end
