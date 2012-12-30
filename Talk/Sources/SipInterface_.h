//
//  SipInterface.h
//  Talk
//
//  Created by Cornelis van der Bent on 29/09/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <pjsua-lib/pjsua.h>

extern NSString* const  kSipInterfaceCallStateChangedNotification;


typedef enum
{
    SipInterfaceRegisteredNo,
    SipInterfaceRegisteredYes,
    SipInterfaceRegisteredFailed
} SipInterfaceRegistered;


@interface SipInterface : NSObject

@property (nonatomic, readonly) NSString*               config;
@property (nonatomic, readonly) SipInterfaceRegistered  registered;

- (id)initWithConfig:(NSString*)config;

- (void)restart;

// A pointer to Call object should passed as userData;
- (pjsua_call_id)callNumber:(NSString*)calledNumber
             identityNumber:(NSString*)identityNumber
                   userData:(void*)userData
                      tones:(NSDictionary*)tones;


- (void)hangupAllCalls;

@end
