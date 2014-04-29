#include <stdio.h>
#include <pthread.h>
#include <unistd.h>
#include <time.h>
#include "mp_listener.h"
#include "GLRenderer.h"
#include "ALRenderer.h"

#define LOG_TAG "mp_listener"

extern GLRenderer *gGLRenderer;
extern ALRenderer *gALRenderer;

MediaPlayerListener::MediaPlayerListener() {
    
}

MediaPlayerListener::~MediaPlayerListener() {

}

void MediaPlayerListener::postEvent(int msg, int ext1, int ext2) {
	
}

int MediaPlayerListener::audioTrackWrite(void* data, int offset, int data_size) {
    [gALRenderer renderPCM:data ofSize:data_size];
    return 0;
}

int MediaPlayerListener::drawFrame(VideoFrame *vf) {
    [gGLRenderer render:vf];
	return 0;
}
