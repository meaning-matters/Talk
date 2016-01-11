//
//  AboutViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface AboutViewController : UIViewController

@property (nonatomic, weak) IBOutlet UILabel*   companyLabel;
@property (nonatomic, weak) IBOutlet UILabel*   versionLabel;
@property (nonatomic, weak) IBOutlet UIButton*  emailButton;
@property (nonatomic, weak) IBOutlet UIButton*  termsButton;
@property (nonatomic, weak) IBOutlet UIButton*  thanksButton;
@property (nonatomic, weak) IBOutlet UIButton*  licensesButton;


- (IBAction)termsAction:(id)sender;

- (IBAction)versionAction:(id)sender;

- (IBAction)thanksAction:(id)sender;

- (IBAction)licensesAction:(id)sender;

@end
