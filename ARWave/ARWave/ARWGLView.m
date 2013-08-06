//
//  ARWGLView.m
//  ARWave
//
//  Created by おもちメタル on 2013/08/06.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#import "ARWGLView.h"

static CVReturn
ARWGLViewDisplayLinkOutputCallback(CVDisplayLinkRef displayLink,
								   const CVTimeStamp* now,
								   const CVTimeStamp* outputTime,
								   CVOptionFlags flagsIn,
								   CVOptionFlags* flagsOut,
								   void* displayLinkContext){
	@autoreleasepool {
		ARWGLView * this = (__bridge ARWGLView *)displayLinkContext;
		return [this displayLinkUpdateHandler:displayLink
										  now:now
								   outputTime:outputTime flagsIn:flagsIn flagsOut:flagsOut];
	}
}

@implementation ARWGLView

-(void)dealloc{
	CVDisplayLinkRelease(_displayLink);
}

-(void)prepareOpenGL{
    GLint swapInt = 1;
    [[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
	
    // Create a display link capable of being used with all active displays
    CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);
	
    // Set the renderer output callback function
    CVDisplayLinkSetOutputCallback(_displayLink, &ARWGLViewDisplayLinkOutputCallback, (__bridge void *)(self));
	
    // Set the display link for the current renderer
    CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
    CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
    CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(_displayLink, cglContext, cglPixelFormat);
	
    // Activate the display link
    CVDisplayLinkStart(_displayLink);
}

-(CVReturn)displayLinkUpdateHandler:(CVDisplayLinkRef)displayLink
								now:(const CVTimeStamp*) now
						 outputTime:(const CVTimeStamp*) outputTime
							flagsIn:(CVOptionFlags)flagsIn
						   flagsOut:(CVOptionFlags*) flagsOut{
	[self.openGLContext makeCurrentContext];
	[self.delegate glView:self displayUpdateWithTime:outputTime];
	[self displayUpdateWithTime:outputTime];
	[NSOpenGLContext clearCurrentContext];
	
	return kCVReturnSuccess;
}

-(void)displayUpdateWithTime:(const CVTimeStamp *)time{
	
}


@end
