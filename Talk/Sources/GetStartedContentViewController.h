//
//  GetStartedContentViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 18/03/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GetStartedContentViewController : UIViewController

@property (nonatomic, weak) IBOutlet UILabel* textLabel;

- (id)initWithText:(NSString*)text;

@end
