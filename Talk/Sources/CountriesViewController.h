//
//  CountriesViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 12/11/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SearchTableViewController.h"


@interface CountriesViewController : SearchTableViewController

@property (nonatomic, assign) BOOL isModal;    // Set this to YES when shown as modal (and not from Settings).

- (instancetype)initWithIsoCountryCode:(NSString*)isoCountryCode
                                 title:(NSString*)title
                            completion:(void (^)(BOOL cancelled, NSString* isoCountryCode))completion;

@end
