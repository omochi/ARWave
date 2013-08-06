//
//  ARWGLView.h
//  ARWave
//
//  Created by おもちメタル on 2013/08/06.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ARWLib.h"

@class ARWGLView;

@protocol ARWGLViewDelegate
-(void)glView:(ARWGLView *)glView updateWithDeltaTime:(double)deltaTime;
@end

@interface ARWGLView : NSOpenGLView
@property(nonatomic,weak)IBOutlet id<ARWGLViewDelegate> delegate;

@property(nonatomic,assign)CVDisplayLinkRef displayLink;
-(CVReturn)displayLinkOutputHandler:(CVDisplayLinkRef)displayLink
								now:(const CVTimeStamp*) now
						 outputTime:(const CVTimeStamp*) outputTime
							flagsIn:(CVOptionFlags)flagsIn
						   flagsOut:(CVOptionFlags*) flagsOut;

-(void)updateFrameHandler;

@end
