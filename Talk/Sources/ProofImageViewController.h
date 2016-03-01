//
//  ProofImageViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 01/09/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@protocol ProofImageViewControllerDelegate <NSObject>

- (void)redoProofImageWithCompletion:(void (^)(UIImage* image))completion;

@end


@interface ProofImageViewController : UIViewController

@property (nonatomic, weak) id<ProofImageViewControllerDelegate> delegate;

- (instancetype)initWithImageData:(NSData*)imageData;

@end
