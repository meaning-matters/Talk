//
//  NumberFilterAreasViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 23/05/17.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import "SearchTableViewController.h"
#import "SearchTableViewController.h"


@interface NumberFilterAreasViewController : SearchTableViewController

- (instancetype)initWithIsoCountryCode:(NSString*)isoCountryCode
                                 areas:(NSArray*)areas
                            completion:(void (^)(NSDictionary* area))completion;

@end
