//
//  Settings.h
//  Talk
//
//  Created by Cornelis van der Bent on 07/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Settings : NSObject

+ (Settings*)sharedSettings;

@property (nonatomic, strong) NSArray*  tabBarViewControllerClasses;

@property (nonatomic, strong) NSString* homeCountry;        // ISO Country Code.
@property (nonatomic, assign) BOOL      homeCountryFromSim;

@end
