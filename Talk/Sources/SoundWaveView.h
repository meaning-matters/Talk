//
//  SoundWaveView.h
//  Talk
//
//  Created by Cornelis van der Bent on 06/07/17.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SoundWaveView;


typedef NS_ENUM(NSUInteger, SoundWaveDirection)
{
    SoundWaveRight = 0,
    SoundWaveLeft  = 1,
};


@interface SoundWaveView : UIView

@property (nonatomic, weak) SoundWaveView*       next;
@property (nonatomic, assign) SoundWaveDirection direction;


- (void)startNextWithColor:(UIColor*)color;

- (void)stop;

@end
