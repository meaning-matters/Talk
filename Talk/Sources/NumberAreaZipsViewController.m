//
//  NumberAreaZipsViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 08/04/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "NumberAreaZipsViewController.h"


@interface NumberAreaZipsViewController ()
{
    NSArray*                zipsArray;
    NSMutableDictionary*    selectedCityZip;
}

@end


@implementation NumberAreaZipsViewController

- (id)initWithZipsArray:(NSArray*)array selectedCityZip:(NSMutableDictionary*)selection
{
    if (self = [super initWithNibName:@"NumberAreaZipsView" bundle:nil])
    {
        zipsArray       = array;
        selectedCityZip = selection;
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

}

@end
