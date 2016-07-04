//
//  NumberTermsViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 03/07/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NumberTermsViewController : UITableViewController

- (instancetype)initWithAgreed:(BOOL)agreed agreedCompletion:(void (^)(void))completion;

@end
