//
//  CountryNames.h
//  Talk
//
//  Created by Cornelis van der Bent on 11/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CountryNames : NSObject

+ (CountryNames*)sharedNames;

- (NSString*)nameForIcc:(NSString*)isoCountryCode;

@end
