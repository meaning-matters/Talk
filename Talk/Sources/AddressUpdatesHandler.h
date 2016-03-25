//
//  AddressUpdatesHandler.h
//  Talk
//
//  Created by Cornelis van der Bent on 13/03/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const AddressUpdatesNotification;


@interface AddressUpdatesHandler : NSObject

+ (AddressUpdatesHandler*)sharedHandler;

- (NSUInteger)addressUpdatesCount;

- (NSDictionary*)addressUpdateWithId:(NSString*)addressId;

- (void)removeAddressUpdateWithId:(NSString*)addressId;

@end
