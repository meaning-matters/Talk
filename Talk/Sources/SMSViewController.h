//
//  SMSViewController.h
//  Talk
//
//  Created by Jeroen Kooiker on 11/9/17.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SearchTableViewController.h"

@class SMSData;

@interface SMSViewController : SearchTableViewController

@property (nonatomic, strong) NSString* headerTitle;
@property (nonatomic, strong) NSString* footerTitle;

@end
