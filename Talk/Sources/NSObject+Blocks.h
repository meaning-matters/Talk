//
//  NSObject+Blocks.h
//  Talk
//
//  Created by Cornelis van der Bent on 07/03/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (Blocks)

- (void)performBlock:(void (^)())block afterDelay:(NSTimeInterval)delay;

@end
