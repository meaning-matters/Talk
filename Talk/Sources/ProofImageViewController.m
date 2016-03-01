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

@end


@implementation ProofImageViewController

- (instancetype)initWithImageData:(NSData*)imageData
{
    if (self = [super init])
    {
        UIImage* image = [UIImage imageWithData:imageData];
        self.imageView = [[UIImageView alloc] initWithImage:image];
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
        height -= self.tabBarController.tabBar.frame.size.height;
    }

    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.frame       = CGRectMake(0.0f, topHeight, self.view.frame.size.width, height);

    [self.view addSubview:self.imageView];

    if (self.delegate != nil)
    {
        UIBarButtonItem* buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                                                                                    target:self
                                                                                    action:@selector(redoAction)];
        self.navigationItem.rightBarButtonItem = buttonItem;
    }
}


- (void)redoAction
{
    [self.delegate redoProofImageWithCompletion:^(UIImage* image)
    {
        if (image != nil)
        {
            self.imageView.image = image;
        }
    }];
}

@end
