//
//  NumberLabel.h
//  Talk
//
//  Created by Cornelis van der Bent on 23/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NumberLabel;

@protocol NumberLabelDelegate <NSObject>

- (void)numberLabelChanged:(NumberLabel*)numberLabel;

@end


@interface NumberLabel : UILabel

@property (nonatomic, assign) id<NumberLabelDelegate>   delegate;

@end
