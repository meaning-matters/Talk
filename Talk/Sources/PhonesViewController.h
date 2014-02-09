//
//  PhonesViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 14/12/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ForwardingData;


@interface PhonesViewController : UITableViewController <NSFetchedResultsControllerDelegate>

- (instancetype)initWithForwarding:(ForwardingData*)forwarding;

@end
