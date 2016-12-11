//
//  CallbackViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 09/10/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CallBaseViewController.h"
#import "Call.h"
#import "PhoneData.h"
#import "CallerIdData.h"


@interface CallbackViewController : CallBaseViewController

- (instancetype)initWithCall:(Call*)call phone:(PhoneData*)phone callerId:(CallableData*)callerId;

@end
