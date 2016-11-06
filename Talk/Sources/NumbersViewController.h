//
//  NumbersViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ItemsViewController.h"

@class NumberData;


@interface NumbersViewController : ItemsViewController

- (void)presentNumber:(NumberData*)number;

- (void)hideNumber:(NumberData*)number;

@end
