//
//  NBRelatedPersonDelegate.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/28/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NBRelatedPersonDelegate <NSObject>
- (void)relatedPersonSelected:(NSString*)personName;
@end
