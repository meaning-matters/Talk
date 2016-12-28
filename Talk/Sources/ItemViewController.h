//
//  ItemViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 26/02/14.
//  Copyright (c) 2014 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface ItemViewController : UITableViewController <UIGestureRecognizerDelegate, UITextFieldDelegate>

@property (nonatomic, strong) id                      item;
@property (nonatomic, strong) NSIndexPath*            nameIndexPath;
@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;


- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;

- (UITableViewCell*)nameCellForRowAtIndexPath:(NSIndexPath*)indexPath;

- (void)cancelAction;

- (UIViewController*)backViewController;

- (void)showSaveError:(NSError*)error
                title:(NSString*)title
             itemName:(NSString*)itemName
           completion:(void (^)(void))completion;

// Must be overriden by subclass.
- (void)save;

// Must be overriden by subclass.
- (void)update;

@end
