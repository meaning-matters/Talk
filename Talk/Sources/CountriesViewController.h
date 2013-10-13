//
//  CountriesViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 12/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CountriesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,
                                                       UISearchBarDelegate, UISearchDisplayDelegate>

@property (nonatomic, weak) IBOutlet UITableView*   tableView;
@property (nonatomic, assign) BOOL                  isModal;           // Set when shown as modal, and not from Settings.

- (instancetype)initWithIsoCountryCode:(NSString*)isoCountryCode
                            completion:(void (^)(BOOL cancelled, NSString* isoCountryCode))completion;

@end
