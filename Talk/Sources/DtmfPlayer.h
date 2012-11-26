//
//  DtmfPlayer.h
//  Talk
//
//  Created by Cornelis van der Bent on 24/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DtmfPlayer : NSObject

+ (DtmfPlayer*)sharedPlayer;

- (void)playForCharacter:(char)character;

- (void)startKeepAlive;

- (void)stopKeepAlive;

@end
