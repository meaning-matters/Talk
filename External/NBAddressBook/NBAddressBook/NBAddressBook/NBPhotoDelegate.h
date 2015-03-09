//
//  NBPhotoDelegate.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/28/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NBPhotoDelegate <NSObject>
- (void)photoEdited:(UIImage*)editedPhoto;
@end
