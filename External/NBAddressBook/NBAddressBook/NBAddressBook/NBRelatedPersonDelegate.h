//
//  NBRelatedPersonDelegate.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/28/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NBRelatedPersonDelegate <NSObject>
- (void)relatedPersonSelected:(NSString*)personName;
@end
