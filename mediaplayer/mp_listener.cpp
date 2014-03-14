#include <stdio.h>
#include <pthread.h>
#include <unistd.h>
#include <time.h>
#include "mp_listener.h"

#define LOG_TAG "mp_listener"

VideoFrame *gVF;
pthread_mutex_t gVFMutex;


MediaPlayerListener::MediaPlayerListener() {
}

MediaPlayerListener::~MediaPlayerListener() {

}

void MediaPlayerListener::postEvent(int msg, int ext1, int ext2) {
	
}

int MediaPlayerListener::audioTrackWrite(void* data, int offset, int data_size) {
    return 0;
}

int MediaPlayerListener::drawFrame(VideoFrame *vf) {
    free(vf->yuv_data[0]);
    free(vf);
	return 0;
}
