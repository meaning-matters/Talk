//
//  NBAddUnknownContactDelegate.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/26/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NBAddUnknownContactDelegate <NSObject>
- (void)replaceViewController:(UIViewController*)viewController;
@end
