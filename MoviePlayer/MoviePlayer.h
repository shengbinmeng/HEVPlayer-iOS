//
//  MoviePlayer.h
//  HEVPlayer
//
//  Created by Shengbin Meng on 13-2-25.
//  Copyright (c) 2013 Peking University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLRenderer.h"
#import "GLView.h"

uint32_t getms();

@interface MoviePlayer : NSObject

@property (retain) UIImageView *imageView;
@property (retain) UILabel *infoLabel;
@property (nonatomic, retain) NSString *infoString;
@property (nonatomic, retain) GLRenderer *renderer;

- (void) setOutputViews:(UIImageView*)imageView :(UILabel*)infoLabel;

- (int) open:(NSString*) path;
- (int) start;
- (int) go;
- (int) pause;
- (int) stop;
- (int) close;

- (double) getMovieTimeInSeconds;
- (double) getMovieDurationInSeconds;
- (int) seekTo:(int64_t) timeInSeconds;
- (BOOL) movieIsPlaying;


@end
