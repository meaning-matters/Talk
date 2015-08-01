//
//  ItemViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 26/02/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ItemViewController : UITableViewController <UIGestureRecognizerDelegate, UITextFieldDelegate>

@property (nonatomic, strong) NSString*               name;           // Mirror that's only processed when user taps Done.
@property (nonatomic, strong) NSIndexPath*            nameIndexPath;
@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;


- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;

- (UITableViewCell*)nameCellForRowAtIndexPath:(NSIndexPath*)indexPath;

- (void)cancelAction;

// Must be overriden by subclass.
- (void)save;

// Must be overriden by subclass.
- (void)update;

@end
