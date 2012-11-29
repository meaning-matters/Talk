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

    callOptionsView = [[CallOptionsView alloc] initWithFrame:self.callRootView.frame];
    callKeypadView  = [[CallKeypadView alloc] initWithFrame:self.callRootView.frame];

    [self.callRootView addSubview:callKeypadView];
    [callKeypadView setNeedsDisplay];
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
