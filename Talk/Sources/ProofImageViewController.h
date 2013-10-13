//
//  ProofImageViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 01/09/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProofImageViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIImageView*   imageView;


- (instancetype)initWithImageData:(NSData*)imageData;

@end
