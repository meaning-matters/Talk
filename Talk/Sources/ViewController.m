//
//  ViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 07/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end


@implementation ViewController

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
        navigationController = [[UINavigationController alloc] initWithRootViewController:self];
#pragma clang diagnostic pop
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
