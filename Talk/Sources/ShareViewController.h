//
//  ShareViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"
#import "ShareButton.h"


@interface ShareViewController : ViewController

@property (nonatomic, weak) IBOutlet ShareButton*   twitterButton;
@property (nonatomic, weak) IBOutlet ShareButton*   facebookButton;
@property (nonatomic, weak) IBOutlet ShareButton*   appStoreButton;
@property (nonatomic, weak) IBOutlet ShareButton*   emailButton;
@property (nonatomic, weak) IBOutlet ShareButton*   messageButton;

@property (nonatomic, weak) IBOutlet UILabel*       thanksLabel;

@end
