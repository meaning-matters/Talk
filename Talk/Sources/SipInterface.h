//
//  SipInterface.h
//  Talk
//
//  Created by Cornelis van der Bent on 29/09/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const  kSipInterfaceCallStateChangedNotification;


@interface SipInterface : NSObject

@property (nonatomic, readonly) NSString*   config;

- (id)initWithConfig:(NSString*)config;

- (void)restart;

@end
