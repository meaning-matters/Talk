//
//  NumberAreaViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 11/03/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NumberType.h"


@interface NumberAreaViewController : UITableViewController

- (instancetype)initWithIsoCountryCode:(NSString*)isoCountryCode
                                 state:(NSDictionary*)state
                                  area:(NSDictionary*)area
                        numberTypeMask:(NumberTypeMask)numberTypeMask;

@end
