//
//  Common.h
//  Talk
//
//  Created by Cornelis van der Bent on 30/09/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Common : NSObject

+ (NSString*)documentFilePath:(NSString*)fileName;

+ (NSData*)dataForResource:(NSString*)resourse ofType:(NSString*)type;

+ (NSString*)bundleVersion;

+ (NSData*)jsonDataWithObject:(id)object;

+ (NSString*)jsonStringWithObject:(id)object;

+ (id)objectWithJsonData:(NSData*)data;

+ (id)objectWithJsonString:(NSString*)string;

//#### Addd: http://stackoverflow.com/questions/1108859/detect-the-specific-iphone-ipod-touch-model
//+ (NSString*)deviceModel;

@end
