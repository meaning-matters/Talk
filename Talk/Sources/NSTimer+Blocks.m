//
//  NSTimer+Blocks.m
//  Talk
//
//  Created by Cornelis van der Bent on 01/12/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//
//  Taken from: https://github.com/bunchjesse/NSTimer-Blocks/tree/ARC-Compatibility

#import "NSTimer+Blocks.h"


@implementation NSTimer (Blocks)

// iOS 10 added a method like this with a block. This caused a crash, to temporary fix I renamed our method
// from the iOS 10 `schedulesTimerWithTimeInterval` to `scheduledTimerWithInterval`. After we move to iOS 10, this
// module can be deleted alltogether.
+ (NSTimer*)scheduledTimerWithInterval:(NSTimeInterval)seconds repeats:(BOOL)repeats block:(void (^)())block
{
    NSTimer* timer = [self scheduledTimerWithTimeInterval:seconds
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
