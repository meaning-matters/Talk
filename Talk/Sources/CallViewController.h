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


@interface CallViewController : UIViewController <CallKeypadViewDelegate>

@property (nonatomic, strong) IBOutlet UIView*          callRootView;

@end
