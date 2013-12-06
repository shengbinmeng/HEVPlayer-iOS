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

#include "libavformat/avformat.h"

struct VideoFrame
{
	int width;
	int height;
	int linesize_y;
	int linesize_uv;
	double pts;
	uint8_t *yuv_data[3];
};

uint32_t getms();

@interface MoviePlayer : NSObject <RenderStateListener>

@property (retain) UIImageView *imageView;
@property (retain) UILabel *infoLabel;
@property (nonatomic, retain) NSString *infoString;
@property (nonatomic, retain) GLRenderer *renderer;

- (void) setOutputViews:(UIImageView*)imageView :(UILabel*)infoLabel;

- (int) openMovie:(NSString*) path;

- (int) play;

- (int) stop;

@end
