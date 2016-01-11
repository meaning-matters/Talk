//
//  NSMutableString+Appending.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/11/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSMutableString (Appending)

- (void)attemptToAppend:(NSString*)toAdd withNewline:(BOOL)newLine;

@end
