//
//  NumberLabel.h
//  Talk
//
//  Created by Cornelis van der Bent on 23/11/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NumberLabel;

@protocol NumberLabelDelegate <NSObject>

- (void)numberLabelChanged:(NumberLabel*)numberLabel;

@end


@interface NumberLabel : UILabel

@property (nonatomic, assign) id<NumberLabelDelegate> delegate;
@property (nonatomic, assign) BOOL                    hasPaste;
@property (nonatomic, assign) CGRect                  menuTargetRect;

@end
