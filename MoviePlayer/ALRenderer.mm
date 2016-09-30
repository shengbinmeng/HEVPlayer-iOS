//
//  ALRenderer.m
//  HEVPlayer
//
//  Created by Shengbin Meng on 4/22/14.
//  Copyright (c) 2014 Peking University. All rights reserved.
//

#import "ALRenderer.h"
#import <OpenAL/al.h>
#import <OpenAL/alc.h>
#import <AudioToolbox/AudioFile.h>
#import <AudioToolbox/ExtendedAudioFile.h>
#include "player_utils.h"

#define BUFFER_NUM 3
#define BUFFER_SIZE (4096 * 4)

@implementation ALRenderer
{
    ALCcontext* _alContext;
    ALCdevice* _alDevice;
    ALuint _alBuffers[BUFFER_NUM];
    ALuint _alSource;
    ALuint _audioFormat;
    ALuint _audioFreqence;
    
    int _setup, _stop;
    uint8_t* _bufferData;
    uint32_t _bufferSize;
}


void checkError()
{
    int error = alGetError();
    if(error != AL_NO_ERROR) {
        LOGE("OpenAL error was raised.\n");
        switch(error) {
            case AL_INVALID_NAME:
                LOGE("Invalid Name paramater passed to AL call.\n");
                break;
            case AL_INVALID_ENUM:
                LOGE("Invalid parameter passed to AL call.\n");
                break;
            case AL_INVALID_VALUE:
                LOGE("Invalid enum parameter value.\n");
                break;
            case AL_INVALID_OPERATION:
                LOGE("Illegal call, i.e., invalid operation.\n");
                break;
            case AL_OUT_OF_MEMORY:
                LOGE("Out of memory.\n");
                break;
            default:
                LOGE("Unknown error.\n");
        }
    }

}

- (bool) isPlaying
{
    ALenum state;
    alGetSourcei(_alSource, AL_SOURCE_STATE, &state);
    return (state == AL_PLAYING);
}

/*
- (void) fillBuffer:(ALuint) bid
{
    AudioData *ad = NULL;
    while (_bufferSize < BUFFER_SIZE) {
        gAudioQueue.get(&ad, true);
        memcpy(_bufferData + _bufferSize, ad->pcm_data, ad->data_size);
        _bufferSize += ad->data_size;
        free(ad->pcm_data);
    }

    alBufferData(bid, _audioFormat, _bufferData, BUFFER_SIZE, _audioFreqence);
    checkError();
    
    _bufferSize = 0;
}

- (void) play
{
    _audioFormat = AL_FORMAT_STEREO16;
    _audioFreqence = 44100;
    
    _setup = 0;
    
    _alDevice = alcOpenDevice(NULL); // select the "preferred device"
    checkError();
    if (_alDevice) {
        // use the device to make a context
        _alContext = alcCreateContext(_alDevice,NULL);
        checkError();
        alcMakeContextCurrent(_alContext);
        checkError();
    }
    
    alGenSources(1, &_alSource);
    checkError();
    alGenBuffers(BUFFER_NUM, _alBuffers);
    checkError();
    
    _bufferData = (uint8_t*) malloc(BUFFER_SIZE);
    _bufferSize = BUFFER_SIZE;
    for (int i = 0; i < BUFFER_NUM; i++) {
        [self fillBuffer:_alBuffers[i]];
    }
    
    alSourceQueueBuffers(_alSource, BUFFER_NUM, _alBuffers);
    checkError();
    
    alSourcePlay(_alSource);
    checkError();

    while (1) {
        int processed = 0;
        alGetSourcei(_alSource, AL_BUFFERS_PROCESSED, &processed);
        LOGI("processed: %d \n", processed);
        checkError();
        while (processed--) {
            ALuint buffer;
            alSourceUnqueueBuffers(_alSource, 1, &buffer);
            checkError();
            
            [self fillBuffer:buffer];
            
            alSourceQueueBuffers(_alSource, 1, &buffer);
            checkError();
            
            LOGD("fill a buffer, processed: %d\n", processed);
        }
        
        if([self isPlaying] == false) {
            LOGD("re-play \n");
            alSourcePlay(_alSource);
            checkError();
        }
        
        usleep(500000);
    }
}

- (id)init
{
    self = [super init];
    if (self == nil) {
        return nil;
    }
    
    [NSThread detachNewThreadSelector:@selector(play) toTarget:self withObject:nil];
    
    return self;
}
 */


- (id)init
{
    self = [super init];
    if (self == nil) {
        return nil;
    }
    
    _audioFormat = AL_FORMAT_STEREO16;
    _audioFreqence = 44100;
    
    _setup = 0;
    _stop = 0;
    
    _alDevice = alcOpenDevice(NULL); // select the "preferred device"
    checkError();
    if (_alDevice) {
        // use the device to make a context
        _alContext = alcCreateContext(_alDevice,NULL);
        checkError();
        alcMakeContextCurrent(_alContext);
        checkError();
    }
    
    alGenSources(1, &_alSource);
    checkError();
    alGenBuffers(BUFFER_NUM, _alBuffers);
    checkError();
    
    return self;
}


- (void) setup
{
    _bufferData = (uint8_t*) malloc(BUFFER_SIZE);
    _bufferSize = 0;
    for (int i = 0; i < BUFFER_NUM; i++) {
        alBufferData(_alBuffers[i], _audioFormat, _bufferData, BUFFER_SIZE, _audioFreqence);
    }
    
    alSourceQueueBuffers(_alSource, BUFFER_NUM, _alBuffers);
    checkError();
    
    alSourcePlay(_alSource);
    checkError();
}

- (void) renderPCM:(void*) data ofSize:(int) size
{
    if (_setup == 0) {
        [self setup];
        _setup = 1;
	}
    
    // make sure there is buffer processed, so we have space to put
    int processed = 0;
    alGetSourcei(_alSource, AL_BUFFERS_PROCESSED, &processed);
    checkError();
    while (processed == 0 && _stop == 0) {
        usleep(100000);
        alGetSourcei(_alSource, AL_BUFFERS_PROCESSED, &processed);
        checkError();
    }
    
    memcpy(_bufferData + _bufferSize, data, size);
    _bufferSize += size;

    if (_bufferSize == BUFFER_SIZE) {
        // put into buffer
        ALuint buffer;
        alSourceUnqueueBuffers(_alSource, 1, &buffer);
        checkError();
        
        alBufferData(buffer, _audioFormat, _bufferData, _bufferSize, _audioFreqence);
        checkError();
        
        alSourceQueueBuffers(_alSource, 1, &buffer);
        checkError();
        
        if (![self isPlaying]) {
            alSourcePlay(_alSource);
            checkError();
        }
        
        _bufferSize = 0;
    }
}



- (void) stop
{
    _stop = 1;
    alSourceStop(_alSource);
}

- (void) dealloc
{
    // delete the source
    alDeleteSources(1, &_alSource);
	
	// delete the buffer
    alDeleteBuffers(BUFFER_NUM, _alBuffers);
	
	// destroy the context
	alcDestroyContext(_alContext);
    
	// close the device
	alcCloseDevice(_alDevice);
}

@end
