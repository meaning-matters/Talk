//
//  ProofImageViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 01/09/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "ProofImageViewController.h"

@interface ProofImageViewController ()
{
    UIImage* image;
}

@end


@implementation ProofImageViewController

- (instancetype)initWithImageData:(NSData*)imageData
{
    if (self = [super initWithNibName:@"ProofImageView" bundle:nil])
    {
        image = [UIImage imageWithData:imageData];
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.imageView.image = image;
}

@end
