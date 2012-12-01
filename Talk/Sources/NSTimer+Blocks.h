//
//  NSTimer+Blocks.h
//  Talk
//
//  Created by Cornelis van der Bent on 01/12/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSTimer (Blocks)

+ (id)scheduledTimerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)())block repeats:(BOOL)repeats;

+ (id)timerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)())block repeats:(BOOL)repeats;

@end