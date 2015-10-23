//
//  RingbackTones.h
//  Talk
//
//  Created by Cornelis van der Bent on 21/12/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RingbackTones : NSObject

@property (nonatomic, strong) NSDictionary* tonesDictionary;

+ (RingbackTones*)sharedTones;

- (NSDictionary*)toneForIsoCountryCode:(NSString*)isoCountryCode;

- (void)check;

@end
