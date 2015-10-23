//
//  Tones.h
//  Talk
//
//  Created by Cornelis van der Bent on 28/12/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Tones : NSObject

@property (nonatomic, strong) NSDictionary* tonesDictionary;

+ (Tones*)sharedTones;

- (NSDictionary*)tonesForIsoCountryCode:(NSString*)isoCountryCode;

@end
