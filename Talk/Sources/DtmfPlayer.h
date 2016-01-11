//
//  DtmfPlayer.h
//  Talk
//
//  Created by Cornelis van der Bent on 24/11/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DtmfPlayer : NSObject

+ (DtmfPlayer*)sharedPlayer;

- (void)playCharacter:(char)character atVolume:(float)volume;

@end
