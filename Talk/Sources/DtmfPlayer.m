//
//  DtmfPlayer.m
//  Talk
//
//  Created by Cornelis van der Bent on 24/11/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import <AVFoundation/AVAudioPlayer.h>
#import "DtmfPlayer.h"


@interface DtmfPlayer ()
{
    NSMutableDictionary*    audioDataObjects;
    AVAudioPlayer*          audioPlayer;    // Needed; can't use local, otherwise ARC releases it immediately.
}

@end


@implementation DtmfPlayer

+ (DtmfPlayer*)sharedPlayer
{
    static DtmfPlayer*     sharedInstance;
    static dispatch_once_t onceToken;

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

        if ([sharedInstance initializeSound:'*' name:@"star"]  == NO ||
            [sharedInstance initializeSound:'#' name:@"pound"] == NO)
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
    NSData*     data = [NSData dataWithContentsOfFile:path options:NSDataReadingUncached error:&error] ;

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
