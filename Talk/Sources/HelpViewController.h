//
//  HelpViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 11/08/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HelpViewController : UIViewController

@property (nonatomic, weak) IBOutlet UITextView*    textView;

- (id)initWithDictionary:(NSDictionary*)dictionary;

@end
