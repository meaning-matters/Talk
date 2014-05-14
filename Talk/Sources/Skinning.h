//
//  Skinning.h
//  Talk
//
//  Created by Cornelis van der Bent on 07/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Skinning : NSObject

+ (Skinning*)sharedSkinning;

+ (UIColor*)tintColor;

+ (UIColor*)onTintColor;    // Used for call button and UISwitch.

+ (UIColor*)deleteTintColor;

+ (UIColor*)backgroundTintColor;

@end
