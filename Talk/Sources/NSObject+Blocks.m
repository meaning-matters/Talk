//
//  NSObject+Blocks.m
//  Talk
//
//  Created by Cornelis van der Bent on 07/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "NSObject+Blocks.h"

@implementation NSObject (Blocks)

- (void)performBlock:(void (^)())block
{
    block();
}


- (void)performBlock:(void (^)())block afterDelay:(NSTimeInterval)delay
{
    void (^copiedBlock)() = [block copy];
    
    [self performSelector:@selector(performBlock:) withObject:copiedBlock afterDelay:delay];
}

@end
