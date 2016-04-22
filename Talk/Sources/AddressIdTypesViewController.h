//
//  AddressIdTypesViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 21/04/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "IdType.h"

@interface AddressIdTypesViewController : UITableViewController

- (instancetype)initWithIdType:(IdType*)idType completion:(void (^)(void))completion;

@end
