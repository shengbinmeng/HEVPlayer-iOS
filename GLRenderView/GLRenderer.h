//
//  GLRenderer.h
//  HEVPlayer
//
//  Created by Shengbin Meng on 11/21/13.
//  Copyright (c) 2013 Peking University. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RenderStateListener
- (void) bufferDone;
@end

@interface GLRenderer : NSObject

- (void) setRenderStateListener:(id<RenderStateListener>) lis;

- (int) resizeFromLayer:(CAEAGLLayer *)layer;

- (void) render: (void*) data;

@end
