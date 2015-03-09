//
//  NBPersonIMCell.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/17/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import "NBPersonFieldTableCell.h"

@interface NBPersonIMCell : NBPersonFieldTableCell
@property (nonatomic) UIView * horiLineView;    //The horizontal separator
@property (nonatomic) UIView * vertiLineView;   //The vertical separator
@property (nonatomic) UILabel* typeLabel;       //The type of IM
@end
