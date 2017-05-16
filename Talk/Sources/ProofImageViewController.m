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
#import "ImagePicker.h"
#import "BlockAlertView.h"
#import "Strings.h"
#import "AddressStatus.h"
#import "DataManager.h"
#import "Common.h"


@interface ProofImageViewController ()

@property (nonatomic, strong) AddressData*   address;
@property (nonatomic, strong) UIImageView*   imageView;
@property (nonatomic, strong) ImagePicker*   imagePicker;
@property (nonatomic, assign) ProofImageType type;
@property (nonatomic, assign) BOOL           editable;
@property (nonatomic, copy)   void (^completion)(BOOL edited);

@end


@implementation ProofImageViewController

- (instancetype)initWithAddress:(AddressData*)address
                           type:(ProofImageType)type
                       editable:(BOOL)editable
                     completion:(void (^)(BOOL edited))completion
{
    if (self = [super init])
    {
        self.address    = address;
        self.type       = type;
        self.editable   = editable;
        self.completion = completion;

        self.imageView  = [[UIImageView alloc] init];

        switch (self.type)
        {
            case ProofImageTypeAddress:
            {
                if (self.address.addressProof != nil)
                {
                    self.imageView.image = [UIImage imageWithData:self.address.addressProof];
                }
                else
                {
                    self.isLoading = YES;

                    __weak typeof(self) weakSelf = self;
                    [self.address loadProofImagesWithCompletion:^(NSError* error)
                    {
                        __strong typeof(weakSelf) strongSelf = weakSelf;
                        strongSelf.isLoading = NO;

                        if (error == nil)
                        {
                            strongSelf.imageView.image = [UIImage imageWithData:strongSelf.address.addressProof];

                            [[DataManager sharedManager] saveManagedObjectContext:nil];
                        }
                        else
                        {
                            [strongSelf showLoadError:error];
                        }
                    }];
                }

                break;
            }
            case ProofImageTypeIdentity:
            {
                if (self.address.identityProof != nil)
                {
                    self.imageView.image = [UIImage imageWithData:self.address.identityProof];
                }
                else
                {
                    self.isLoading = YES;

                    __weak typeof(self) weakSelf = self;
                    [self.address loadProofImagesWithCompletion:^(NSError* error)
                    {
                        __strong typeof(weakSelf) strongSelf = weakSelf;
                        strongSelf.isLoading = NO;

                        if (error == nil)
                        {
                            strongSelf.imageView.image = [UIImage imageWithData:strongSelf.address.identityProof];

                            [[DataManager sharedManager] saveManagedObjectContext:nil];
                        }
                        else
                        {
                            [strongSelf showLoadError:error];
                        }
                    }];
                }

                break;
            }
        }
    }

    return self;
}


- (void)showLoadError:(NSError*)error
{
    NSString* title   = NSLocalizedString(@"Error Loading Image", @"");
    NSString* message = NSLocalizedString(@"Loading this proof image failed: %@\n\nPlease try again later.", @"");
    message = [NSString stringWithFormat:message, error.localizedDescription];

    [BlockAlertView showAlertViewWithTitle:title message:message completion:^(BOOL cancelled, NSInteger buttonIndex)
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
                         cancelButtonTitle:[Strings closeString]
                         otherButtonTitles:nil];
}


- (void)dealloc
{
    if (self.isLoading)
    {
        [self.address cancelLoadProofImages];

        self.isLoading = NO;
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [Skinning backgroundTintColor];

    [self.view addSubview:self.imageView];

    if (self.editable)
    {
        UIBarButtonItem* buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                                                                                    target:self
                                                                                    action:@selector(pickImageAction)];
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
                self.imageView.image = [UIImage imageWithData:imageData];

                switch (self.type)
                {
                    case ProofImageTypeAddress:
                    {
                        self.address.addressProof    = imageData;
                        self.address.addressProofMd5 = [Common md5ForData:imageData];

                        break;
                    }
                    case ProofImageTypeIdentity:
                    {
                        self.address.identityProof    = imageData;
                        self.address.identityProofMd5 = [Common md5ForData:imageData];

                        break;
                    }
                }

                // Wait for image picker to disappear, so that below pop animation becomes visible.
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
                {
                    self.completion ? self.completion(self.editable) : 0;

                    [self.navigationController popViewControllerAnimated:YES];
                });
            }
        }];
    }
}


- (BOOL)canPickImage
{
    NSString* title;
    NSString* message;

    switch (self.address.addressStatus)
    {
        case AddressStatusUnknown:
        {
            break;
        }
        case AddressStatusStagedMask:
        {
            break;
        }
        case AddressStatusVerificationNotRequiredMask:
        {
            break;
        }
        case AddressStatusDisabledMask:
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
        case AddressStatusVerifiedMask:
        {
            break;
        }
        case AddressStatusNotVerifiedMask:  // Fall-through.
        case AddressStatusVerificationRequestedMask:
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
        case AddressStatusRejectedMask:
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
