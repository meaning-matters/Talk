//
//  NumberExtendViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 13/07/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NumberData.h"


@interface NumberExtendViewController : UITableViewController

- (instancetype)initWithNumber:(NumberData*)number completion:(void (^)(void))completion;

@end
