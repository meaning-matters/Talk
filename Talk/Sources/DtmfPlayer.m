//
//  DtmfPlayer.m
//  Talk
//
//  Created by Cornelis van der Bent on 24/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "DtmfPlayer.h"

static NSMutableDictionary* soundIds;


@implementation DtmfPlayer

+ (BOOL)initializeSound:(char)character name:(NSString*)name
{
    NSString*       path = [NSString stringWithFormat:@"/System/Library/Audio/UISounds/dtmf-%@.caf", name];
    NSURL*          url  = [NSURL fileURLWithPath:path isDirectory:NO];
    SystemSoundID   soundId;
    OSStatus        status = AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &soundId);

    if (url != nil || status == kAudioServicesNoError)
    {
        [soundIds setObject:[NSNumber numberWithInt:soundId] forKey:[NSString stringWithFormat:@"%c", character]];

        return YES;
    }
    else
    {
        return NO;
    }
}


+ (void)initialize
{
    soundIds = [NSMutableDictionary dictionary];

    for (char character = '0'; character <= '9'; character++)
    {
        if ([DtmfPlayer initializeSound:character name:[NSString stringWithFormat:@"%c", character]] == NO)
        {
            NSLog(@"Error creating DTMF sound.");
            break;
        }
    }

    if ([DtmfPlayer initializeSound:'*' name:@"star"] == NO ||
        [DtmfPlayer initializeSound:'#' name:@"pound"]== NO)
    {
        NSLog(@"Error creating DTMF sound.");
    }
}


+ (void)playForCharacter:(char)character
{
    SystemSoundID soundId = [[soundIds objectForKey:[NSString stringWithFormat:@"%c", character]] intValue];

    AudioServicesPlaySystemSound(soundId);
}

@end
