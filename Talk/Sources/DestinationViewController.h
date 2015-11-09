//
//  DestinationViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 27/04/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "DestinationData.h"
#import "ItemViewController.h"


@interface DestinationViewController : ItemViewController <UITextFieldDelegate>

@property (nonatomic, strong) DestinationData* destination;
@property (nonatomic, strong) NSMutableArray*  sequenceArray;

- (instancetype)initWithDestination:(DestinationData*)destination
               managedObjectContext:(NSManagedObjectContext*)managedObjectContext;

@end
