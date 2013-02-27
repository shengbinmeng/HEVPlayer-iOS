//
//  MoviePlayer.h
//  HEVPlayer
//
//  Created by Shengbin Meng on 13-2-25.
//  Copyright (c) 2013年 Peking University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MoviePlayer : NSObject
@property (retain) UIImageView *imageView;
@property (retain) UILabel *infoLabel;

- (void) setOutputViews:(UIImageView*)imageView :(UILabel*)infoLabel;

- (int) openMovie:(NSString*) path;
- (int) play;
- (int) stop;
@end
