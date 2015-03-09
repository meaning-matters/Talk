//
//  NBDetailLineSeparatedCell.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/6/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//
//  A cell with a line separator between them

#import <UIKit/UIKit.h>
#import "NBPersonFieldTableCell.h"

@interface NBDetailLineSeparatedCell : NBPersonFieldTableCell
@property (nonatomic) UIView * lineView;
@end
