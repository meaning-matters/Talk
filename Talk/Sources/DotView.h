//
//  DotView.h
//  Talk
//
//  Created by Cornelis van der Bent on 04/03/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface DotView : UIView

- (instancetype)init;

- (void)addToCell:(UITableViewCell*)cell;

+ (DotView*)getFromCell:(UITableViewCell*)cell;

@end
