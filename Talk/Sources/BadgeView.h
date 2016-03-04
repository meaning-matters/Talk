//
//  BadgeView.h
//  Talk
//
//  Created by Cornelis van der Bent on 04/03/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BadgeView : UIView

@property (nonatomic, assign) NSUInteger count;

- (instancetype)init;

- (void)addToCell:(UITableViewCell*)cell;

@end
