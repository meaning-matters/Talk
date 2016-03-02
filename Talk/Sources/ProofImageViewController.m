//
//  ProofImageViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 01/09/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "ProofImageViewController.h"
#import "UIViewController+Common.h"
#import "Skinning.h"
#import "WebClient.h"
#import "Base64.h"


@interface ProofImageViewController ()

@property (nonatomic, strong) AddressData* address;
@property (nonatomic, strong) UIImageView* imageView;

@end


@implementation ProofImageViewController

- (instancetype)initWithAddress:(AddressData*)address
{
    if (self = [super init])
    {
        self.address   = address;
        self.imageView = [[UIImageView alloc] init];

        if (self.address.proofImage != nil)
        {
            self.imageView.image = [UIImage imageWithData:[Base64 decode:self.address.proofImage]];
        }
        else
        {
            self.isLoading = YES;

            __weak typeof(self) weakSelf = self;
            [self.address loadProofImageWithCompletion:^(BOOL succeeded)
            {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                strongSelf.isLoading = NO;

                strongSelf.imageView.image = [UIImage imageWithData:[Base64 decode:strongSelf.address.proofImage]];
            }];
        }
    }

    return self;
}


- (void)dealloc
{
    if (self.isLoading)
    {
        [self.address cancelLoadProofImage];

        self.isLoading = NO;
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [Skinning backgroundTintColor];

    [self.view addSubview:self.imageView];

    if (self.delegate != nil)
    {
        UIBarButtonItem* buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                                                                                    target:self
                                                                                    action:@selector(redoAction)];
        self.navigationItem.rightBarButtonItem = buttonItem;
    }
}


- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    CGFloat topHeight = 64.0f;  // iOS status bar plus navigation bar.
    CGFloat height    = self.view.frame.size.height - topHeight;
    if (self.tabBarController)
    {
        height -= self.tabBarController.tabBar.frame.size.height;
    }

    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.frame       = CGRectMake(0.0f, topHeight, self.view.frame.size.width, height);
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
