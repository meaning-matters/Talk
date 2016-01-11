//
//  NBRecentContactViewController.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/20/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NBPersonViewController.h"
#import "NBCallsView.h"

@interface NBRecentContactViewController : NBPersonViewController
{
}

- (void)setRecentEntryArray:(NSArray*)entryArray;

@end
