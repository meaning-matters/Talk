//
//  NBRecentCallCell.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/20/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define SIZE_NUMBER_LABEL               200
#define POSITION_NUMBER_LABEL           (40 + 6)
#define POSITION_NUMBER_LABEL_EDITING   (53 + 6)


@interface NBRecentCallCell : UITableViewCell
{
    // The original label colors, mutated when highlighted
    UIColor* originalTitleColor;
    UIColor* originalDetailColor;
}

@property (nonatomic) UILabel*     numberLabel;
@property (nonatomic) UILabel*     numberTypeLabel;
@property (nonatomic) UILabel*     callerIdLabel;
@property (nonatomic) UIImageView* callerIdImageView;

// Animation methods
- (void)shiftLabels:(BOOL)shift;

@end
