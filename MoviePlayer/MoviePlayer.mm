//
//  MoviePlayer.m
//  HEVPlayer
//
//  Created by Shengbin Meng on 13-2-25.
//  Copyright (c) 2013 Peking University. All rights reserved.
//

#import "MoviePlayer.h"
#import "GLRenderer.h"
#include "mediaplayer.h"

@implementation MoviePlayer
{
    NSString *moviePath;
    NSThread *decodeThread;
    BOOL isBusy, stopRender;
    MediaPlayer *gMP;
}

- (id) init
{
    self = [super init];
    
    MediaPlayer *mp = new MediaPlayer();
    MediaPlayerListener* listener = new MediaPlayerListener();
	mp->setListener(listener);
    gMP = mp;
    return self;
}

- (void) setOutputViews:(UIImageView*)anImageView :(UILabel*)anInfoLabel
{
    self.imageView = anImageView;
    self.infoLabel = anInfoLabel;
}

- (int) open:(NSString*) path
{
    moviePath = path;
	char * filepath = (char*)[moviePath UTF8String];
    gMP->open(filepath);
    gMP->setLoopPlay(1);
    return 0;
}

- (int) start
{
    return gMP->start();
}

- (int) go
{
    return gMP->go();
}

- (int) pause
{
    return gMP->pause();
}

- (int) stop
{
    return gMP->stop();
}

- (int) close
{
    return gMP->close();
}

- (double) getMovieTimeInSeconds
{
    int msec = -1;
    gMP->getCurrentPosition(&msec);
    return msec/1000.0;
}

- (double) getMovieDurationInSeconds
{
    int msec = -1;
    gMP->getDuration(&msec);
    return msec/1000.0;
}

- (int) seekTo:(int64_t) timeInSeconds
{
    return gMP->seekTo(timeInSeconds*1000);
}

- (BOOL) movieIsPlaying
{
    return gMP->isPlaying();
}

@end
