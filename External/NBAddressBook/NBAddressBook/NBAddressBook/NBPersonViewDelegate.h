//
//  NBPersonViewDelegate.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/15/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NBPersonViewDelegate <NSObject>
- (void)scrollToRow:(id)object;
@end
