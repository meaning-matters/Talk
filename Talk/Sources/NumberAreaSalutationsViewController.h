//
//  NumberAreaSalutationsViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 18/08/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Salutation.h"


@interface NumberAreaSalutationsViewController : UITableViewController

- (instancetype)initWithSalutation:(Salutation*)salutation completion:(void (^)(void))completion;

@end
