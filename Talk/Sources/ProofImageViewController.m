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
#import "ImagePicker.h"
#import "BlockAlertView.h"
#import "Strings.h"


@interface ProofImageViewController ()

@property (nonatomic, strong) AddressData* address;
@property (nonatomic, strong) UIImageView* imageView;
@property (nonatomic, strong) ImagePicker* imagePicker;

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
            self.imageView.image = [UIImage imageWithData:self.address.proofImage];
        }
        else
        {
            self.isLoading = YES;

            __weak typeof(self) weakSelf = self;
            [self.address loadProofImageWithCompletion:^(BOOL succeeded)
            {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                strongSelf.isLoading = NO;

                strongSelf.imageView.image = [UIImage imageWithData:strongSelf.address.proofImage];
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

    UIBarButtonItem* buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                                                                                target:self
                                                                                action:@selector(pickImageAction)];
    self.navigationItem.rightBarButtonItem = buttonItem;
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


- (void)pickImageAction
{
    if ([self canPickImage])
    {
        if (self.imagePicker == nil)
        {
            self.imagePicker = [[ImagePicker alloc] initWithPresentingViewController:self];
        }

        [self.imagePicker pickImageWithCompletion:^(NSData* imageData)
        {
            if (imageData != nil)
            {
                self.imageView.image    = [UIImage imageWithData:imageData];

                self.address.proofImage = imageData;
                self.address.hasProof   = YES;
            }
        }];
    }
}


- (BOOL)canPickImage
{
    NSString* title;
    NSString* message;

    switch (self.address.status)
    {
        case AddressStatusUnknown:
        {
            break;
        }
        case AddressStatusNotVerified:
        {
            break;
        }
        case AddressStatusDisabled:
        {
            // Don't know when this occurs, it at all.
            title   = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                        @"Can't Take Photo",
                                                        @"....\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                        @"You can't take a proof image because your address has been "
                                                        @"disabled.",
                                                        @"....\n"
                                                        @"[iOS alert message size]");
            break;
        }
        case AddressStatusVerified:
        {
            break;
        }
        case AddressStatusVerificationRequested:
        {
            title   = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                        @"Can't Take Photo",
                                                        @"....\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                        @"You can't take a new proof image because your address is "
                                                        @"waiting to be verified.",
                                                        @"....\n"
                                                        @"[iOS alert message size]");
            break;
        }
        case AddressStatusRejected:
        {
            break;
        }
    }

    if (title != nil)
    {
        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:nil
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];
        return NO;
    }
    else
    {
        return YES;
    }
}

@end
