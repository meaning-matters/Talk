//
//  ProofImageViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 01/09/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "ProofImageViewController.h"
#import "Skinning.h"


@interface ProofImageViewController ()

@property (nonatomic, strong) UIImageView* imageView;
@property (nonatomic, strong) UIImage*     image;

@end


@implementation ProofImageViewController

- (instancetype)initWithImageData:(NSData*)imageData
{
    if (self = [super init])
    {
        self.image = [UIImage imageWithData:imageData];
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [Skinning backgroundTintColor];

    CGFloat topHeight = 64.0f;  // iOS status bar plus navigation bar.
    CGFloat height    = self.view.frame.size.height - topHeight;
    if (self.tabBarController)
    {
        height -= self.tabBarController.view.frame.size.height;
    }

    self.imageView = [[UIImageView alloc] initWithImage:self.image];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;

    self.imageView.frame = CGRectMake(0.0f, topHeight, self.view.frame.size.width, height);

    [self.view addSubview:self.imageView];
}

@end
