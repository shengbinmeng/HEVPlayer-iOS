//
//  AudioHandler.h
//  HEVPlayer
//
//  Created by Shengbin Meng on 4/22/14.
//  Copyright (c) 2014 Peking University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioHandler : NSObject

- (id) init;
- (void) startPlayback;
- (void) pausePlayback;
- (void) stopPlayback;

@end
