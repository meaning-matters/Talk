//
//  MessagesViewController.h
//  Talk
//
//  Created by Jeroen Kooiker on 11/9/17.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ItemsViewController.h"


@interface MessagesViewController : ItemsViewController

@property (nonatomic, strong) NSString* headerTitle;
@property (nonatomic, strong) NSString* footerTitle;

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;

@end
