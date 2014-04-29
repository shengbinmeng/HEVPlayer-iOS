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

#define ENABLE_LOGD 1
#if ENABLE_LOGD
#define LOGD(...) printf(__VA_ARGS__)
#else
#define LOGD(...)
#endif
#define LOGI(...) printf(__VA_ARGS__)
#define LOGE LOGI

#define BUFFER_NUM 3
#define BUFFER_SIZE (4096 * 8)

@implementation ALRenderer
{
    ALCcontext* _alContext;
    ALCdevice* _alDevice;
    ALuint _alBuffers[BUFFER_NUM];
    ALuint _alSource;
    ALuint _audioFormat;
    ALuint _audioFreqence;
    
    int _setup;
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

- (bool) playing
{
    ALenum state;
    
    alGetSourcei(_alSource, AL_SOURCE_STATE, &state);
    
    return (state == AL_PLAYING);
}

- (void) setup
{
    //alcMakeContextCurrent(_alContext);
    checkError();
}


- (id)init
{
    self = [super init];
    if (self == nil) {
        return nil;
    }
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
    alSourcei(_alSource, AL_BUFFER, 0);
    checkError();

    
    alSource3f(_alSource, AL_POSITION,        0.0, 0.0, 0.0);
    alSource3f(_alSource, AL_VELOCITY,        0.0, 0.0, 0.0);
    alSource3f(_alSource, AL_DIRECTION,       0.0, 0.0, 0.0);
    alSourcef (_alSource, AL_ROLLOFF_FACTOR,  0.0          );
    alSourcei (_alSource, AL_SOURCE_RELATIVE, AL_TRUE      );
    alSourcei(_alSource, AL_LOOPING, AL_FALSE);
    
    
    _bufferData = malloc(BUFFER_SIZE);
    _bufferSize = 0;
    for (int i = 0; i < BUFFER_NUM; i++) {
        alGenBuffers(1, &_alBuffers[i]);
        checkError();
        
        alBufferData(_alBuffers[i], _audioFormat, _bufferData, BUFFER_SIZE, _audioFreqence);
        checkError();

        alSourceQueueBuffers(_alSource, 1, &_alBuffers[i]);
        checkError();
    }
    
    alSourcePlay(_alSource);
    checkError();

    
    return self;
}


- (void) renderPCM:(void*) data ofSize:(int) size
{
    [self renderPCM2:data ofSize:size]; return;
    LOGD("render an audio PCM data, size: %d \n", size);
    if (_setup == 0) {
        [self setup];
        _setup = 1;
	}
    
    // make sure there is buffer processed, so we have space to put
    int processed = 0;
    alGetSourcei(_alSource, AL_BUFFERS_PROCESSED, &processed);
    LOGD("processed: %d \n", processed);
    checkError();
    while (processed == 0) {
        usleep(1000000);
        LOGD("in while, sleep zzzzzzzz\n");
        
        alGetSourcei(_alSource, AL_BUFFERS_PROCESSED, &processed);
        checkError();
        LOGD("after sleep, processed: %d \n", processed);
    }
    
    // put into buffer
    ALuint buffer;
    alSourceUnqueueBuffers(_alSource, 1, &buffer);
    checkError();
    LOGD("buffer: %d \n", buffer);
    alBufferData(buffer, _audioFormat, data, size, _audioFreqence);
    
    alSourceQueueBuffers(_alSource, 1, &buffer);
    checkError();
    
    
    if (![self playing]) {
        LOGD("not playing !\n");
        //alSourcePlay(_alSource);
    }

}

- (void) renderPCM2:(void*) data ofSize:(int) size
{
    if (![self playing]) {
        //LOGD("not playing !\n");
        //alSourcePlay(_alSource);
        //return;
    }

    LOGD("render an audio PCM data, size: %d \n", size);
    if (_setup == 0) {
        [self setup];
        _setup = 1;
	}
    
    // make sure there is buffer processed, so we have space to put
    int processed = 0;
    alGetSourcei(_alSource, AL_BUFFERS_PROCESSED, &processed);
    LOGD("processed: %d \n", processed);
    checkError();
    while (processed == 0) {
        usleep(250000);
        LOGD("in while, sleep zzzzzzzz\n");
        
        alGetSourcei(_alSource, AL_BUFFERS_PROCESSED, &processed);
        checkError();
        LOGD("after sleep, processed: %d \n", processed);
    }
    
    memcpy(_bufferData + _bufferSize, data, size);
    _bufferSize += size;
    if (_bufferSize == BUFFER_SIZE) {
        // put into buffer
        ALuint buffer;
        alSourceUnqueueBuffers(_alSource, 1, &buffer);
        checkError();
        LOGD("buffer: %d \n", buffer);
        alBufferData(buffer, _audioFormat, _bufferData, _bufferSize, _audioFreqence);
        
        alSourceQueueBuffers(_alSource, 1, &buffer);
        checkError();
        _bufferSize = 0;
    }
    
    LOGD("_bufferSize: %d \n", _bufferSize);
    
}






- (void) stop
{
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
