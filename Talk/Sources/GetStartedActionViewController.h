//
//  GetStartedActionViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 19/03/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GetStartedActionViewController : UIViewController

@property (nonatomic, weak) IBOutlet UILabel*                 textLabel;
@property (nonatomic, weak) IBOutlet UIButton*                button;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activityIndicator;

- (IBAction)buttonAction:(id)sender;

- (void)setBusy:(BOOL)busy;
- (void)restoreCreditAndData;

@end
