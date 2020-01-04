//
//  GetStartedViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 16/03/14.
//  Copyright (c) 2014 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface GetStartedViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic, weak) IBOutlet UIScrollView*       scrollView;
@property (nonatomic, weak) IBOutlet UIPageControl*      pageControl;
@property (nonatomic, weak) IBOutlet UIButton*           restoreButton;
@property (nonatomic, weak) IBOutlet UIButton*           startButton;
@property (nonatomic, weak) IBOutlet UILabel*            internetLabel;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* pageControlBottomContstraint;

- (id)initShowAsIntro:(BOOL)showAsIntro;

- (IBAction)changePage:(id)sender;
- (IBAction)startAction:(id)sender;
- (IBAction)restoreAction:(id)sender;

@end
