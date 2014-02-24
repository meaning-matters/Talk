//
//  NumberStatesViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 06/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SearchTableViewController.h"
#import "NumberType.h"


@interface NumberStatesViewController : SearchTableViewController <UITableViewDelegate>

- (instancetype)initWithIsoCountryCode:(NSString*)isoCountryCode
                        numberTypeMask:(NumberTypeMask)numberTypeMask;

@end
