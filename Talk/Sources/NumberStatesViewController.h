//
//  NumberStatesViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 06/03/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SearchTableViewController.h"
#import "NumberType.h"


@interface NumberStatesViewController : SearchTableViewController <UITableViewDelegate>

- (instancetype)initWithIsoCountryCode:(NSString*)isoCountryCode
                        numberTypeMask:(NumberTypeMask)numberTypeMask;

@end
