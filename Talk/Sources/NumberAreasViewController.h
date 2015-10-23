//
//  NumberAreasViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 09/03/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SearchTableViewController.h"
#import "NumberType.h"


@interface NumberAreasViewController : SearchTableViewController <UITableViewDelegate>

- (instancetype)initWithIsoCountryCode:(NSString*)isoCountryCode
                                 state:(NSDictionary*)state
                        numberTypeMask:(NumberTypeMask)numberTypeMask;

@end
