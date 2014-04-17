#include <stdio.h>
#include <pthread.h>
#include <unistd.h>
#include <time.h>
#include "mp_listener.h"
#include "GLRenderer.h"

#define LOG_TAG "mp_listener"

extern GLRenderer *gRenderer;

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
    [gRenderer render:vf];
	return 0;
}
