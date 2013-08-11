//
//  HelpViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 11/08/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "HelpViewController.h"


@interface HelpViewController ()
{
    NSString*   helpText;
}

@end


@implementation HelpViewController

- (id)initWithDictionary:(NSDictionary*)dictionary
{
    if (self = [super initWithNibName:@"HelpView" bundle:nil])
    {
        self.title  = [dictionary allKeys][0];

        helpText    = [dictionary allValues][0];
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.textView.text = helpText;
}

@end
