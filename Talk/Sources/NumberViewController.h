//
//  NumberViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 27/03/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NumberData.h"
#import "ItemViewController.h"


@interface NumberViewController : ItemViewController <UITextFieldDelegate>

- (instancetype)initWithNumber:(NumberData*)number;

@end
