//
//  CellBadgeView.h
//  Talk
//
//  Created by Cornelis van der Bent on 04/03/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CellBadgeView : UIView

@property (nonatomic, assign) NSUInteger count;

+ (void)addToCell:(UITableViewCell*)cell count:(NSUInteger)count;

@end
