//
//  AudioHandler.m
//  HEVPlayer
//
//  Created by Shengbin Meng on 4/22/14.
//  Copyright (c) 2014 Peking University. All rights reserved.
//

#import "AudioHandler.h"
#import <AudioToolbox/AudioToolbox.h>

@implementation AudioHandler
{
    AudioUnit _audioUnit;
    OSStatus _status;

}


- (id) init
{
    self = [super init];
    
    // Describe audio component
    AudioComponentDescription desc;
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_RemoteIO;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // Enable IO for playback
    
    UInt32 flag = 1;
    _status = AudioUnitSetProperty(_audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Output,
                                  0,
                                  &flag,
                                  sizeof(flag));
    
    return  self;
}

- (void) startPlayback
{
    
}

- (void) pausePlayback
{
    
}

- (void) stopPlayback
{
    
}

@end
