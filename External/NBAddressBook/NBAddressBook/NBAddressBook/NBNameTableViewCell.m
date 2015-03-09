//
//  NBNameTableViewCell.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/4/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import "NBNameTableViewCell.h"

@implementation NBNameTableViewCell

//Slightly move the frame
- (void)setFrame:(CGRect)frame
{
    frame.origin.x += SPACE_NAME_CELL_INSET;
    frame.size.width -= SPACE_NAME_CELL_INSET;
    [super setFrame:frame];
}
@end
