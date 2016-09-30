//
//  MoviePlayer.m
//  HEVPlayer
//
//  Created by Shengbin Meng on 13-2-25.
//  Copyright (c) 2013 Peking University. All rights reserved.
//

#import "MoviePlayer.h"
#import "GLRenderer.h"
#import "ALRenderer.h"
#include "mediaplayer.h"

GLRenderer *gGLRenderer;
ALRenderer *gALRenderer;

@implementation MoviePlayer
{
    MediaPlayer *_mediaPlayer;
}

- (id) init
{
    self = [super init];
    
    MediaPlayer *mp = new MediaPlayer();
    MediaPlayerListener* listener = new MediaPlayerListener();
	mp->setListener(listener);
    _mediaPlayer = mp;
    return self;
}

- (void) setOutputViews:(UIImageView*)anImageView :(UILabel*)anInfoLabel
{
    self.imageView = anImageView;
    self.infoLabel = anInfoLabel;
}

- (int) open:(NSString*) path
{
	char * filepath = (char*)[path UTF8String];
    int ret = _mediaPlayer->open(filepath);
    return ret;
}

- (int) start
{
    gGLRenderer = self.renderer;
    gALRenderer = [[ALRenderer alloc] init];
    _mediaPlayer->setLoopPlay(1);
    return _mediaPlayer->start();
}

- (int) go
{
    return _mediaPlayer->go();
}

- (int) pause
{
    return _mediaPlayer->pause();
}

- (int) stop
{
    [gALRenderer stop];
    gALRenderer = nil;
    return _mediaPlayer->stop();
}

- (int) close
{
    return _mediaPlayer->close();
}

- (double) getMovieTimeInSeconds
{
    int msec = -1;
    _mediaPlayer->getCurrentPosition(&msec);
    return msec/1000.0;
}

- (double) getMovieDurationInSeconds
{
    int msec = -1;
    _mediaPlayer->getDuration(&msec);
    return msec/1000.0;
}

- (int) seekTo:(int64_t) timeInSeconds
{
    return _mediaPlayer->seekTo(timeInSeconds*1000);
}

- (BOOL) movieIsPlaying
{
    return _mediaPlayer->isPlaying();
}

@end
