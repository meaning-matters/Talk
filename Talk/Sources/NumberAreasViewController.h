//
//  NumberAreasViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 09/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NumberType.h"


@interface NumberAreasViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,
                                                         UISearchBarDelegate, UISearchDisplayDelegate>

@property (nonatomic, weak) IBOutlet UISegmentedControl*    numberTypeSegmentedControl;
@property (nonatomic, weak) IBOutlet UITableView*           tableView;

- (id)initWithCountry:(NSDictionary*)country
              stateId:(NSString*)stateId
       numberTypeMask:(NumberTypeMask)numberTypeMask;

- (IBAction)numberTypeChangedAction:(id)sender;

@end
