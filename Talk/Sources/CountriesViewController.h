//
//  CountriesViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 12/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CountriesViewController : UIViewController <UISearchDisplayDelegate, UISearchBarDelegate,
                                                       UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, assign) BOOL                  isModal;    // Set when shown as modal, and not from Settings.
@property (nonatomic, retain) IBOutlet UITableView* tableView;

- (instancetype)initWithIsoCountryCode:(NSString*)isoCountryCode
                            completion:(void (^)(BOOL cancelled, NSString* isoCountryCode))completion;

@end
