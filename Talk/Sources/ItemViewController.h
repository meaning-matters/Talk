//
//  ItemViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 26/02/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ItemViewController : UITableViewController <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSString*    name;           // Mirror that's only processed when user taps Done.
@property (nonatomic, strong) NSIndexPath* nameIndexPath;

// Must be overriden by subclass.
- (void)save;

@end
