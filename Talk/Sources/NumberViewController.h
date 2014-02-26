//
//  NumberViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 27/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NumberData.h"
#import "ItemViewController.h"


@interface NumberViewController : ItemViewController <UITextFieldDelegate, UINavigationControllerDelegate>

- (instancetype)initWithNumber:(NumberData*)number;

@end
