//
//  GraphicCallStateView.h
//  Talk
//
//  Created by Cornelis van der Bent on 30/11/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CallStateView.h"


@interface GraphicCallStateView : CallStateView

@property (nonatomic, assign) BOOL            callingContact;

@property (nonatomic, weak) IBOutlet UILabel* phoneLabel;
@property (nonatomic, weak) IBOutlet UILabel* callerIdLabel;
@property (nonatomic, weak) IBOutlet UILabel* stateLabel;

- (void)startRequest;
- (void)stopRequest;

- (void)startCallback;
- (void)stopCallback;
- (void)connectCallback;

- (void)startCallthru;
- (void)stopCallthru;
- (void)connectCallthru;

@end
