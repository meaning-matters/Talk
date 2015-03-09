//
//  NBEditPhotoViewController.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/25/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import "NBEditPhotoViewController.h"

#define ALPHA_BOUNDS 0.5f

@implementation NBEditPhotoViewController

@synthesize imageToEdit;

- (void)viewDidLoad
{
    [super viewDidLoad];

    //Create the scrollView
    CGSize screenSize = self.view.frame.size;
    imageScrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 0, screenSize.width, screenSize.height)];
    [imageScrollView setBackgroundColor:[UIColor clearColor]];
    [imageScrollView setDelegate:self];
    [imageScrollView setClipsToBounds:YES];
    [imageScrollView setShowsHorizontalScrollIndicator:NO];
    [imageScrollView setShowsVerticalScrollIndicator:NO];
    
    //Create and add the imageview
    imageView = [[UIImageView alloc]initWithFrame:imageScrollView.frame];
    [imageView setBackgroundColor:[UIColor clearColor]];
    [imageView setContentMode:UIViewContentModeScaleAspectFit];
    [imageView setImage:imageToEdit];
    [imageScrollView setContentSize:CGSizeMake(imageView.frame.size.width, imageView.frame.size.height)];
    [imageScrollView addSubview:imageView];
    [self.view addSubview:imageScrollView];
    
    //Calculate minimum scale to perfectly fit image width, and begin at that scale
    float widthDelta    = [imageScrollView frame].size.width  / [imageView frame].size.width;
    float heightDelta   = [imageScrollView frame].size.height  / [imageView frame].size.height;
    float minimumScale  = ( widthDelta < heightDelta ? widthDelta : heightDelta);
    imageScrollView.maximumZoomScale = 3.0;
    imageScrollView.minimumZoomScale = minimumScale;
    imageScrollView.zoomScale = minimumScale;
    
    //Add the top bound
    topBoundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
    topBoundView.backgroundColor = [UIColor blackColor];
    
    //Scale the bar proportionally
    CGRect topImageFrame = topBoundView.frame;
    float topFactor = topImageFrame.size.height / topImageFrame.size.width;
    topImageFrame.size.width = self.view.frame.size.width;
    topImageFrame.size.height = topImageFrame.size.width * topFactor;
    topBoundView.frame = topImageFrame;
    [topBoundView setContentMode:UIViewContentModeScaleAspectFill];
    topBoundView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [topBoundView setAlpha:ALPHA_BOUNDS];
    [self.view addSubview:topBoundView];
    
    //Add a description label
    UILabel * descriptionLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];
    [descriptionLabel setBackgroundColor:[UIColor clearColor]];
    [descriptionLabel setCenter:topBoundView.center];
    [descriptionLabel setTextColor:[UIColor whiteColor]];
    [descriptionLabel setTextAlignment:NSTextAlignmentCenter];
    [descriptionLabel setFont:[UIFont systemFontOfSize:20]];
    [descriptionLabel setText:NSLocalizedString(@"PHT_MOVE_AND_SCALE", @"")];
    [topBoundView addSubview:descriptionLabel];
    
    //Add the bottom bound
    UIImage * bottomImage = [UIImage imageNamed:@"editPhotoBottomBar"];
    bottomBoundView = [[UIImageView alloc]initWithImage:bottomImage];
    
    //Scale the bar proportionally
    CGRect bottomImageFrame = bottomBoundView.frame;
    float bottomFactor = bottomImageFrame.size.height / bottomImageFrame.size.width;
    bottomImageFrame.size.width = self.view.frame.size.width;
    bottomImageFrame.size.height = bottomImageFrame.size.width * bottomFactor;
    bottomImageFrame.origin.y = self.view.frame.size.height - bottomImageFrame.size.height;    
    bottomBoundView.frame = bottomImageFrame;
    [bottomBoundView setContentMode:UIViewContentModeScaleAspectFill];
    bottomBoundView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [bottomBoundView setAlpha:ALPHA_BOUNDS];
    [self.view addSubview:bottomBoundView];

    //Add the cancel-button frame
    leftButtonBackground = [[UIImageView alloc]initWithImage:[self createDummyImage]];
    leftButtonBackground.alpha = 0;
    float buttonBackgroundFactor = leftButtonBackground.frame.size.height / leftButtonBackground.frame.size.width;
    CGRect leftButtonBackgroundFrame = leftButtonBackground.frame;
    leftButtonBackgroundFrame.size.width = bottomImageFrame.size.width / 2.5;
    leftButtonBackgroundFrame.size.height = leftButtonBackgroundFrame.size.width * buttonBackgroundFactor;
    [leftButtonBackground setFrame:leftButtonBackgroundFrame];
    [leftButtonBackground setCenter:CGPointMake(bottomBoundView.center.x - (self.view.frame.size.width/4) , bottomBoundView.center.y)];
    [self.view addSubview:leftButtonBackground];
    
    //Set the cancel-button itself
    cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelButton.backgroundColor = [UIColor clearColor];
    [cancelButton setFrame:CGRectMake(0, 0, 120, 45)];
    float buttonFactor = cancelButton.frame.size.height / cancelButton.frame.size.width;
    CGRect cancelButtonFrame = cancelButton.frame;
    cancelButtonFrame.size.width = bottomImageFrame.size.width / 2.65;
    cancelButtonFrame.size.height = cancelButtonFrame.size.width * buttonFactor;
    [cancelButton setFrame:cancelButtonFrame];
    [cancelButton setCenter:leftButtonBackground.center];
    [cancelButton addTarget:self action:@selector(cancelPressed) forControlEvents:UIControlEventTouchUpInside];
    
    //Set the cancel button title
    [cancelButton setTitle:NSLocalizedString(@"NCT_CANCEL", @"") forState:UIControlStateNormal];
    [cancelButton.titleLabel setFont:[UIFont systemFontOfSize:20]];
    [self.view addSubview:cancelButton];
    
    //Add the choose-button
    rightButtonBackground = [[UIImageView alloc]initWithImage:[self createDummyImage]];
    rightButtonBackground.alpha = 0;
    [rightButtonBackground setFrame:leftButtonBackgroundFrame];
    [rightButtonBackground setCenter:CGPointMake(bottomBoundView.center.x + (self.view.frame.size.width/4) , bottomBoundView.center.y)];
    [self.view addSubview:rightButtonBackground];
    
    //Set the choose-button itself
    selectButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [selectButton setFrame:cancelButtonFrame];
    [selectButton setCenter:rightButtonBackground.center];
    [selectButton addTarget:self action:@selector(donePressed) forControlEvents:UIControlEventTouchUpInside];
    
    //Set the choose-title
    [selectButton setTitle:NSLocalizedString(@"PHT_CHOOSE", @"") forState:UIControlStateNormal];
    [selectButton.titleLabel setFont:[UIFont systemFontOfSize:20]];
    [selectButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    selectButton.backgroundColor = [UIColor clearColor];
    [self.view addSubview:selectButton];
}


- (UIImage*)createDummyImage
{
    CGSize size = CGSizeMake(133, 52);
    UIGraphicsBeginImageContextWithOptions(size, YES, 0);
    [[UIColor whiteColor] setFill];
    UIRectFill(CGRectMake(0, 0, size.width, size.height));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

#pragma mark - Button delegates
- (void)donePressed
{
    //Hide the controls
    [self hideControls:YES];
    
    //Screenshot the image
    UIGraphicsBeginImageContextWithOptions([self.view bounds].size, self.view.opaque, 1.0);
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *croppedAndScaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    //Cut out a square rectangle
    CGImageRef imageRef = CGImageCreateWithImageInRect([croppedAndScaledImage CGImage], CGRectMake(0, topBoundView.frame.size.height, croppedAndScaledImage.size.width, croppedAndScaledImage.size.width));
    croppedAndScaledImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    //Notify the listening party
    [self.photoDelegate photoEdited:croppedAndScaledImage];
    [self setPhotoDelegate:nil];
    
    //Dismiss the view
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cancelPressed
{
    [self setPhotoDelegate:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Quick hiding/showing of controls
- (void)hideControls:(BOOL)hide
{
    [topBoundView setHidden:hide];
    [bottomBoundView setHidden:hide];
    [leftButtonBackground setHidden:hide];
    [cancelButton setHidden:hide];
    [rightButtonBackground setHidden:hide];
    [selectButton setHidden:hide];
}

#pragma mark - UIScrollViewDelegate methods
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return imageView;
}

@end
