//
//  ShareViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "ShareButton.h"


@interface ShareViewController : UIViewController <MFMessageComposeViewControllerDelegate,
                                                   MFMailComposeViewControllerDelegate>

@property (nonatomic, weak) IBOutlet ShareButton*   twitterButton;
@property (nonatomic, weak) IBOutlet ShareButton*   facebookButton;
@property (nonatomic, weak) IBOutlet ShareButton*   appStoreButton;
@property (nonatomic, weak) IBOutlet ShareButton*   emailButton;
@property (nonatomic, weak) IBOutlet ShareButton*   messageButton;

@property (nonatomic, weak) IBOutlet UILabel*       thanksLabel;


- (IBAction)twitterAction:(id)sender;

- (IBAction)facebookAction:(id)sender;

- (IBAction)appStoreAction:(id)sender;

- (IBAction)emailAction:(id)sender;

- (IBAction)messageAction:(id)sender;

@end
