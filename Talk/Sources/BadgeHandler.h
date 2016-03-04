//
//  BadgeHandler.h
//  Talk
//
//  Created by Cornelis van der Bent on 03/03/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BadgeHandler : NSObject

@property (nonatomic, assign) NSUInteger numbersBadgeCount;

+ (BadgeHandler*)sharedHandler;

- (void)decrementNumbersBadgeCount;

- (void)updateMoreBadgeCount;

- (void)updateAllBadgeCounts;

@end
