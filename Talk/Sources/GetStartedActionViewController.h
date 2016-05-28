//
//  GetStartedActionViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 19/03/14.
//  Copyright (c) 2014 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface GetStartedActionViewController : UIViewController

@property (nonatomic, weak) IBOutlet UILabel*                 titleLabel;
@property (nonatomic, weak) IBOutlet UITextView*              textView;
@property (nonatomic, weak) IBOutlet UIButton*                button;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* busyIndicator;

- (IBAction)buttonAction:(id)sender;

- (void)setBusy:(BOOL)busy;
- (void)restoreUserData;

@end
