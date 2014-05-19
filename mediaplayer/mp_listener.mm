#include <stdio.h>
#include <pthread.h>
#include <unistd.h>
#include <time.h>
#include "mp_listener.h"
#include "GLRenderer.h"
#include "ALRenderer.h"
#include "audioqueue.h"
#include "player_utils.h"

#define LOG_TAG "mp_listener"

extern GLRenderer *gGLRenderer;
extern ALRenderer *gALRenderer;
extern AudioQueue gAudioQueue;

MediaPlayerListener::MediaPlayerListener() {
    
}

MediaPlayerListener::~MediaPlayerListener() {

}

void MediaPlayerListener::postEvent(int msg, int ext1, int ext2) {
	
}

int MediaPlayerListener::audioTrackWrite(void* data, int offset, int data_size) {

    [gALRenderer renderPCM:data ofSize:data_size];
    return 0;
    
    while (gAudioQueue.size() > 4) {
        usleep(100000);
        LOGI("waiting for audio queue ...\n");
    }

    // allocate a video frame, copy data to it, and put it in the frame queue
    AudioData *ad = (AudioData*) malloc(sizeof(AudioData));
	if (ad == NULL) {
		LOGE("vf malloc failed \n");
	}
	ad->pcm_data = (uint8_t*) malloc(data_size);
	if (ad->pcm_data == NULL) {
		LOGE("pcm_data malloc failed \n");
	}
	memcpy(ad->pcm_data, data, data_size);
    ad->data_size = data_size;
    gAudioQueue.put(ad);
    
    return 0;
}

int MediaPlayerListener::drawFrame(VideoFrame *vf) {
    [gGLRenderer render:vf];
	return 0;
}
