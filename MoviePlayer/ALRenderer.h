//
//  ALRenderer.h
//  HEVPlayer
//
//  Created by Shengbin Meng on 4/22/14.
//  Copyright (c) 2014 Peking University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ALRenderer : NSObject

- (void) renderPCM:(void*)data ofSize:(int)size;

- (void) stop;

@end
