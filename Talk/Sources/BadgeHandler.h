//
//  BadgeHandler.h
//  Talk
//
//  Created by Cornelis van der Bent on 03/03/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface BadgeHandler : NSObject <UITableViewDataSource>

@property (nonatomic, weak) id<UITableViewDataSource> moreTableDataSource;

+ (BadgeHandler*)sharedHandler;

- (void)setBadgeCount:(NSUInteger)count forViewController:(UIViewController*)viewController;

- (void)update;

- (void)hideBadges; // Used when editing More.

- (void)showBadges; // Used when editing More.

@end
