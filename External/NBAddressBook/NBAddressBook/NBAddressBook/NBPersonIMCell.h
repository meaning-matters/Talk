//
//  NBPersonIMCell.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/17/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NBPersonFieldTableCell.h"


@interface NBPersonIMCell : NBPersonFieldTableCell

@property (nonatomic) UIView * horiLineView;    //The horizontal separator
@property (nonatomic) UIView * vertiLineView;   //The vertical separator
@property (nonatomic) UILabel* typeLabel;       //The type of IM

@end
