//
//  NBEditPhotoViewController.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/25/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "NBPhotoDelegate.h"

#define ZOOM_STEP 1.5

@interface NBEditPhotoViewController : UIViewController <UIScrollViewDelegate>
{
    //The image-and scrollview
    UIScrollView *imageScrollView;
    UIImageView *imageView;
    
    //The top and bottom view bar
    UIView * topBoundView;
    UIImageView * bottomBoundView;
    
    //The buttons
    UIImageView *   leftButtonBackground;
    UIButton *      cancelButton;
    UIImageView *   rightButtonBackground;
    UIButton *      selectButton;
}

@property (nonatomic) UIImage * imageToEdit;
@property (nonatomic) id<NBPhotoDelegate> photoDelegate;

@end
