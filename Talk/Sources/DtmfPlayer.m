//
//  DtmfPlayer.m
//  Talk
//
//  Created by Cornelis van der Bent on 24/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <AVFoundation/AVAudioPlayer.h>
#import "DtmfPlayer.h"

static NSMutableDictionary* audioDataObjects;


@implementation DtmfPlayer


+ (BOOL)initializeSound:(char)character name:(NSString*)name
{
    NSError*    error = nil;
    NSString*   path = [NSString stringWithFormat:@"/System/Library/Audio/UISounds/dtmf-%@.caf", name];
    NSData*     data = [NSData dataWithContentsOfFile:path options:NSDataReadingMapped error:&error] ;

    if (error == nil && data != nil)
    {
        [audioDataObjects setObject:data forKey:[NSString stringWithFormat:@"%c", character]];

        return YES;
    }
    else
    {
        return NO;
    }
}


+ (void)initialize
{
    audioDataObjects = [NSMutableDictionary dictionary];

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


+ (void)playForCharacter:(char)character
{
    static AVAudioPlayer*   audioPlayer;    // Needs to be static, otherwise ARC releases it immediately.
    NSData*                 data;
    NSError*                error = nil;

    data = [audioDataObjects objectForKey:[NSString stringWithFormat:@"%c", character]];
    audioPlayer = [[AVAudioPlayer alloc] initWithData:data error:&error];
    audioPlayer.volume= 0.02f;
    [audioPlayer prepareToPlay];

    [audioPlayer play];
}

@end
