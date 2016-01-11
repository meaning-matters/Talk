//
//  NBNotesCell.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/12/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NBDetailLineSeparatedCell.h"


@interface NBNotesCell : NBDetailLineSeparatedCell
{
    CGRect originalFrame;
}

@property (nonatomic) UITextView * cellTextview;
@end
