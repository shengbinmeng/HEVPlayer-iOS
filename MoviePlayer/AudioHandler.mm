//
//  AudioHandler.m
//  HEVPlayer
//
//  Created by Shengbin Meng on 4/22/14.
//  Copyright (c) 2014 Peking University. All rights reserved.
//

#import "AudioHandler.h"
#import <AudioToolbox/AudioToolbox.h>
#include "audioqueue.h"

extern AudioQueue gAudioQueue;

static OSStatus playbackCallback(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData) {
    
    for (int i = 0; i < ioData->mNumberBuffers; i++) {
        AudioBuffer buffer = ioData->mBuffers[i];
        AudioData *ad = NULL;
        gAudioQueue.get(&ad, true);
        
        uint32_t size = buffer.mDataByteSize < ad->data_size ? buffer.mDataByteSize : ad->data_size;
        memcpy(buffer.mData, ad->pcm_data, size);
        buffer.mDataByteSize = size;
        buffer.mNumberChannels = 2;
        
        free(ad->pcm_data);
    }
    
    return noErr;
}


void checkStatus(int status){
    if (status) {
        printf("Status not 0! %d\n", status);
    }
}

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
    
    // Get component
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
    
    // Get audio units
    _status = AudioComponentInstanceNew(inputComponent, &_audioUnit);
    checkStatus(_status);
    
    // Enable IO for playback
    UInt32 flag = 1;
    _status = AudioUnitSetProperty(_audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Output,
                                  0,
                                  &flag,
                                  sizeof(flag));
    checkStatus(_status);
    
    // Describe format
    AudioStreamBasicDescription audioFormat;
    audioFormat.mSampleRate			= 44100.00;
    audioFormat.mFormatID			= kAudioFormatLinearPCM;
    audioFormat.mFormatFlags		= kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioFormat.mFramesPerPacket	= 1;
    audioFormat.mChannelsPerFrame	= 2;
    audioFormat.mBitsPerChannel		= 16;
    audioFormat.mBytesPerPacket		= 4;
    audioFormat.mBytesPerFrame		= 4;
    
    // Apply format
    _status = AudioUnitSetProperty(_audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  1,
                                  &audioFormat,
                                  sizeof(audioFormat));
    checkStatus(_status);
    
    // Set output callback
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = playbackCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)(self);
    _status = AudioUnitSetProperty(_audioUnit,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Global,
                                  0,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    checkStatus(_status);

    return  self;
}

- (void) startPlayback
{
    OSStatus status = AudioOutputUnitStart(_audioUnit);
    checkStatus(status);
}

- (void) pausePlayback
{
    
}

- (void) stopPlayback
{
    OSStatus status = AudioOutputUnitStop(_audioUnit);
    checkStatus(status);
}

@end
