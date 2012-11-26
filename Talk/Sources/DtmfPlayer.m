//
//  DtmfPlayer.m
//  Talk
//
//  Created by Cornelis van der Bent on 24/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//
//  The keep-alive works around a weird play delay that kicks in after about 5 seconds
//  of not having played anything.  By playing something silently, the delay is prevented.
//  Other people have seen similar delays, and the solution given is to use lower
//  level APIs.  I don't want to spend more time on this, and choose work around.

#import <AVFoundation/AVAudioPlayer.h>
#import "DtmfPlayer.h"


@interface DtmfPlayer ()
{
    NSMutableDictionary*    audioDataObjects;
    NSTimer*                keepAliveTimer;
    AVAudioPlayer*          audioPlayer;    // Needed; can't use local, otherwise ARC releases it immediately.
}

@end


@implementation DtmfPlayer

static DtmfPlayer*  sharedPlayer;


+ (BOOL)initializeSound:(char)character name:(NSString*)name
{
    NSError*    error = nil;
    NSString*   path = [NSString stringWithFormat:@"/System/Library/Audio/UISounds/dtmf-%@.caf", name];
    NSData*     data = [NSData dataWithContentsOfFile:path options:NSDataReadingMapped error:&error] ;

    if (error == nil && data != nil)
    {
        [sharedPlayer->audioDataObjects setObject:data forKey:[NSString stringWithFormat:@"%c", character]];

        return YES;
    }
    else
    {
        return NO;
    }
}


+ (void)initialize
{
    if ([DtmfPlayer class] == self)
    {
        sharedPlayer = [self new];

        sharedPlayer->audioDataObjects = [NSMutableDictionary dictionary];

        for (char character = '0'; character <= '9'; character++)
        {
            if ([DtmfPlayer initializeSound:character name:[NSString stringWithFormat:@"%c", character]] == NO)
            {
                NSLog(@"Error loading DTMF sound.");
                break;
            }
        }

        if ([DtmfPlayer initializeSound:'*' name:@"star"] == NO ||
            [DtmfPlayer initializeSound:'#' name:@"pound"]== NO)
        {
            NSLog(@"Error loading DTMF sound.");
        }
    }
}


+ (id)allocWithZone:(NSZone*)zone
{
    if (sharedPlayer && [DtmfPlayer class] == self)
    {
        [NSException raise:NSGenericException format:@"Duplicate DtmfPlayer singleton creation"];
    }

    return [super allocWithZone:zone];
}


+ (DtmfPlayer*)sharedPlayer
{
    return sharedPlayer;
}


- (void)startKeepAlive
{
    if (keepAliveTimer == nil)
    {
        keepAliveTimer = [NSTimer scheduledTimerWithTimeInterval:4
                                                          target:sharedPlayer
                                                        selector:@selector(playKeepAlive)
                                                        userInfo:nil
                                                         repeats:YES];
    }
}


- (void)stopKeepAlive
{
    [keepAliveTimer invalidate];
    keepAliveTimer = nil;
}


- (void)playKeepAlive
{
    if ([audioPlayer isPlaying] == NO)
    {
        NSData*                 data;
        NSError*                error = nil;

        data = [audioDataObjects objectForKey:[NSString stringWithFormat:@"%c", '0']];
        audioPlayer = [[AVAudioPlayer alloc] initWithData:data error:&error];
        audioPlayer.volume= 0.00001f;
        [audioPlayer prepareToPlay];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                       {
                           [audioPlayer play];
                       });
    }
}


- (void)playForCharacter:(char)character
{
    NSData*                 data;
    NSError*                error = nil;

    data = [audioDataObjects objectForKey:[NSString stringWithFormat:@"%c", character]];
    audioPlayer = [[AVAudioPlayer alloc] initWithData:data error:&error];
    audioPlayer.volume= 0.02f;
    [audioPlayer prepareToPlay];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                   {
                       [audioPlayer play];
                   });
}

@end
