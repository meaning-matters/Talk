//
//  ExtendNumberViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 14/07/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NumberType.h"


@interface ExtendNumberViewController : UITableViewController

- (instancetype)initWithE164:(NSString*)e164;

@end
