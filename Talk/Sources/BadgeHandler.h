//
//  BadgeHandler.h
//  Talk
//
//  Created by Cornelis van der Bent on 03/03/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const BadgeHandlerAddressUpdatesNotification;


@interface BadgeHandler : NSObject <UITableViewDataSource>

@property (nonatomic, weak) id<UITableViewDataSource> moreTableDataSource;

+ (BadgeHandler*)sharedHandler;

- (NSDictionary*)addressUpdates;

- (NSUInteger)addressUpdatesCount;

- (void)removeAddressUpdate:(NSString*)addressId;

- (void)update;

- (UITabBarItem*)tabBarItemForViewController:(UIViewController*)viewController;

@end
