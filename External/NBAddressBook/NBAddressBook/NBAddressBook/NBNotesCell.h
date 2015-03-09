//
//  NBNotesCell.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/12/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import "NBDetailLineSeparatedCell.h"

@interface NBNotesCell : NBDetailLineSeparatedCell
{
    CGRect originalFrame;
}

@property (nonatomic) UITextView * cellTextview;
@end
