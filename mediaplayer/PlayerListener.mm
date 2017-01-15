#include <stdio.h>
#include <pthread.h>
#include <unistd.h>
#include <time.h>
#include "PlayerListener.h"
#include "GLRenderer.h"
#include "ALRenderer.h"
#include "player_utils.h"

#define LOG_TAG "PlayerListener"

extern GLRenderer *gGLRenderer;
extern ALRenderer *gALRenderer;

PlayerListener::PlayerListener() {
    
}

PlayerListener::~PlayerListener() {

}

void PlayerListener::postEvent(int msg, int ext1, int ext2) {
	
}

int PlayerListener::audioTrackWrite(void* data, int offset, int data_size) {
    [gALRenderer renderPCM:data ofSize:data_size];
    return 0;
}

int PlayerListener::drawFrame(VideoFrame *vf) {
    [gGLRenderer render:vf];
	return 0;
}
