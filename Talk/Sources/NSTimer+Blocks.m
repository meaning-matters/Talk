//
//  NSTimer+Blocks.m
//  Talk
//
//  Created by Cornelis van der Bent on 01/12/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//
//  Taken from: https://github.com/bunchjesse/NSTimer-Blocks/tree/ARC-Compatibility

#import "NSTimer+Blocks.h"


@implementation NSTimer (Blocks)

+ (id)scheduledTimerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)())block repeats:(BOOL)repeats
{
    id timer = [self scheduledTimerWithTimeInterval:seconds
                                             target:self
                                           selector:@selector(executeBlock:)
                                           userInfo:[block copy]
                                            repeats:repeats];
    
    return timer;
}


+ (id)timerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)())block repeats:(BOOL)repeats
{
    id timer = [self timerWithTimeInterval:seconds
                                    target:self
                                  selector:@selector(executeBlock:)
                                  userInfo:[block copy]
                                   repeats:repeats];
    
    return timer;
}


+ (void)executeBlock:(NSTimer*)timer
{
    if ([timer userInfo])
    {
        void (^block)() = (void (^)())[timer userInfo];
        
        block();
    }
}

@end
