//
//  BuyNumberViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 14/07/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BuyNumberViewController : UITableViewController

@property (nonatomic, strong) NSDictionary* area;

- (id)initWithArea:(NSDictionary*)area;

@end
