//
//  NSMutableString+Appending.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/11/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import "NSMutableString+Appending.h"

@implementation NSMutableString (Appending)

//Support-method to only append if there is content
- (void)attemptToAppend:(NSString*)toAdd withNewline:(BOOL)newLine
{
    if (toAdd != nil && [toAdd length] > 0)
    {
        if (newLine)
        {
            [self appendFormat:@"%@%@", toAdd, @"\n"];
        }
        else
        {
            [self appendFormat:@" %@", toAdd];
        }
    }
}

@end
