//
//  AddressPhotoCell.h
//  Talk
//
//  Created by Cornelis van der Bent on 15/04/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@protocol AddressPhotoCellDelegate <NSObject>

- (void)takePhotoAction;

@end


@interface AddressPhotoCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIButton*           button;
@property (nonatomic, weak) id<AddressPhotoCellDelegate> delegate;

@end
