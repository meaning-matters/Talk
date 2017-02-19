//
//  AddressUpdatesHandler.h
//  Talk
//
//  Created by Cornelis van der Bent on 13/03/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AddressData;

extern NSString* const AddressUpdatesNotification;


@interface AddressUpdatesHandler : NSObject

+ (AddressUpdatesHandler*)sharedHandler;

- (void)processChangedAddress:(AddressData*)address;

- (NSUInteger)badgeCount;

- (NSDictionary*)addressUpdateWithUuid:(NSString*)uuid;

- (void)removeAddressUpdateWithUuid:(NSString*)uuid;

@end
