//
//  ImagePicker.h
//  Talk
//
//  Created by Cornelis van der Bent on 02/03/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImagePicker : NSObject

- (instancetype)initWithPresentingViewController:(UIViewController*)presentingViewController;

- (void)pickImageWithTitle:(NSString*)title completion:(void (^)(NSData* imageData))completion;

@end
