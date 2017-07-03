//
//  NumberFilterViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 22/05/17.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NumberFilterViewControllerDelegate <NSObject>

/**
 *  Checks if filter parameters in Settings are complete. Make sure the Settings.numberFilter values are set appropriately
 *  before calling this method!
 *
 *  @return YES if Settings.numberFilter has been sufficiently set, otherwise NO.
 */
- (BOOL)isFilterComplete;

@end


@interface NumberFilterViewController : UITableViewController

- (instancetype)initWithNumberCountries:(NSArray*)numberCountries
                               delegate:(id<NumberFilterViewControllerDelegate>)delegate
                             completion:(void (^)())completion;

@end
