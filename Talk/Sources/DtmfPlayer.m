//
//  DtmfPlayer.m
//  Talk
//
//  Created by Cornelis van der Bent on 24/11/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
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

+ (DtmfPlayer*)sharedPlayer
{
    static DtmfPlayer*      sharedInstance;
    static dispatch_once_t  onceToken;

    dispatch_once(&onceToken, ^
    {
        sharedInstance = [[DtmfPlayer alloc] init];

        sharedInstance->audioDataObjects = [NSMutableDictionary dictionary];

        for (char character = '0'; character <= '9'; character++)
        {
            if ([sharedInstance initializeSound:character name:[NSString stringWithFormat:@"%c", character]] == NO)
            {
                NBLog(@"Error loading DTMF sound.");
                break;
            }
        }

        if ([sharedInstance initializeSound:'*' name:@"star"] == NO ||
            [sharedInstance initializeSound:'#' name:@"pound"]== NO)
        {
            NBLog(@"Error loading DTMF sound.");
        }
    });
    
    return sharedInstance;
}


- (BOOL)initializeSound:(char)character name:(NSString*)name
{
    NSError*    error = nil;
    NSString*   path = [NSString stringWithFormat:@"/System/Library/Audio/UISounds/dtmf-%@.caf", name];
    NSData*     data = [NSData dataWithContentsOfFile:path options:NSDataReadingMapped error:&error] ;

    if (error == nil && data != nil)
    {
        audioDataObjects[[NSString stringWithFormat:@"%c", character]] = data;

        return YES;
    }
    else
    {
        return NO;
    }
}


- (void)startKeepAlive
{
    if (keepAliveTimer == nil)
    {
        keepAliveTimer = [NSTimer scheduledTimerWithTimeInterval:4
                                                          target:self
                                                        selector:@selector(playKeepAlive)
                                                        userInfo:nil
                                                         repeats:YES];
        [self playKeepAlive];
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
        [self playCharacter:'0' atVolume:0.00001f];
    }
}


- (void)playCharacter:(char)character atVolume:(float)volume
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
    {
        NSData*     data;
        NSError*    error = nil;

        data = audioDataObjects[[NSString stringWithFormat:@"%c", character]];
        audioPlayer = [[AVAudioPlayer alloc] initWithData:data error:&error];
        audioPlayer.volume = volume;
        [audioPlayer play];
    });
}

@end
