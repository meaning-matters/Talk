//
//  NSTimer+Blocks.h
//  Talk
//
//  Created by Cornelis van der Bent on 01/12/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSTimer (Blocks)

+ (NSTimer*)scheduledTimerWithTimeInterval:(NSTimeInterval)seconds repeats:(BOOL)repeats block:(void (^)())block;

+ (NSTimer*)timerWithTimeInterval:(NSTimeInterval)seconds repeats:(BOOL)repeats block:(void (^)())block;

@end