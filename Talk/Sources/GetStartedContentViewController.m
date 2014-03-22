//
//  GetStartedContentViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 18/03/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import "GetStartedContentViewController.h"

@interface GetStartedContentViewController ()

@property (nonatomic, strong) NSString* text;

@end


@implementation GetStartedContentViewController

- (id)initWithText:(NSString*)text
{
    if (self = [super initWithNibName:@"GetStartedContentView" bundle:nil])
    {
        self.text = text;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.textLabel.text = self.text;
}

@end
