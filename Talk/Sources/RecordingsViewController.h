//
//  RecordingsViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 14/02/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import "ItemsViewController.h"

@class RecordingData;


@interface RecordingsViewController : ItemsViewController

@property (nonatomic, strong) NSString* headerTitle;
@property (nonatomic, strong) NSString* footerTitle;


- (instancetype)init;

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                           selectedRecording:(RecordingData*)selectedRecording
                                  completion:(void (^)(RecordingData* selectedRecording))completion;

@end
