//
//  LicenseViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 26/05/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface LicenseViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIWebView* webView;

- (instancetype)initWithDictionary:(NSDictionary*)dictionary;

@end
