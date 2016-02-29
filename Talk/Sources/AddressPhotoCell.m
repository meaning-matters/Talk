//
//  AddressPhotoCell.m
//  Talk
//
//  Created by Cornelis van der Bent on 15/04/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "AddressPhotoCell.h"


@implementation AddressPhotoCell

- (IBAction)buttonAction:(id)sender
{
    [self.delegate takePhotoAction];
}

@end
