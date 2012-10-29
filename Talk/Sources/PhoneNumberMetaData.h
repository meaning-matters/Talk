//
//  PhoneNumberMetaData.h
//  Talk
//
//  Created by Cornelis van der Bent on 28/10/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PhoneNumberMetaData : NSObject <NSXMLParserDelegate>

@property (nonatomic, readonly) NSDictionary*   metaData;
@property (nonatomic, readonly) NSDictionary*   countryCodeMap;

+ (PhoneNumberMetaData*)sharedInstance;

@end
