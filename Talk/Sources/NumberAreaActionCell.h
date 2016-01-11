//
//  NumberAreaActionCell.h
//  Talk
//
//  Created by Cornelis van der Bent on 15/04/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface NumberAreaActionCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel*                 label;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activityIndicator;

@end
