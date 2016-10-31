//
//  CallManager.h
//  Talk
//
//  Created by Cornelis van der Bent on 23/11/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhoneNumber.h"
#import "Call.h"
#import "CallRecordData.h"


@interface CallManager : NSObject

@property (nonatomic, strong) NSMutableArray* activeCalls;


+ (CallManager*)sharedManager;

- (void)callPhoneNumber:(PhoneNumber*)phoneNumber
              contactId:(NSString*)contactId
             completion:(void (^)(Call* call))completion;

- (void)endCall:(Call*)call;

- (BOOL)callMobilePhoneNumber:(PhoneNumber*)phoneNumber;

- (void)updateRecent:(CallRecordData*)recent withCall:(Call*)call;

- (void)updateRecent:(CallRecordData*)recent completion:(void (^)(BOOL success, BOOL ended))completion;

@end
