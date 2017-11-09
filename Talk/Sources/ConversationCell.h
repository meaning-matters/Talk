//
//  ConversationCell.h
//  Talk
//
//  Created by Jeroen Kooiker on 23/10/2017.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ConversationCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel* nameNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel* textPreviewLabel;
@property (weak, nonatomic) IBOutlet UILabel* timestampLabel;

@end
