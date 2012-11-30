//
//  CallViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 26/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "CallViewController.h"


@interface CallViewController ()
{
    CallOptionsView*    callOptionsView;
    CallKeypadView*     callKeypadView;
}

@end


@implementation CallViewController

@synthesize callRootView = _callRootView;


- (id)init
{
    if (self = [super initWithNibName:@"CallView" bundle:nil])
    {
        callKeypadView.delegate = self;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    CGRect  frame = CGRectMake(0, 0, self.callRootView.frame.size.width, self.callRootView.frame.size.height);
    callOptionsView = [[CallOptionsView alloc] initWithFrame:frame];
    callKeypadView  = [[CallKeypadView alloc] initWithFrame:frame];

    [self.callRootView addSubview:callOptionsView];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - Keypad Delegate

- (void)callKeypadView:(CallKeypadView *)keypadView pressedDigitKey:(KeypadKey)key
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
