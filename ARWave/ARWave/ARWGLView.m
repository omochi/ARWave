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
		return [this displayLinkOutputHandler:displayLink
										  now:now
								   outputTime:outputTime flagsIn:flagsIn flagsOut:flagsOut];
	}
}

@interface ARWGLView()
@property(nonatomic,assign)uint64_t frameCount;
@property(nonatomic,strong)NSDate * fpsCountStartTime;
@property(nonatomic,assign)int fpsFrameCount;
@property(nonatomic,assign)int actualFps;
@property(nonatomic,strong)NSDate * prevUpdateTime;

@property(atomic,assign)BOOL updating;
@end

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
		
	self.frameCount = 0;
	self.fpsCountStartTime = [NSDate date];
	self.fpsFrameCount = 0;
	self.actualFps = 0;
	self.prevUpdateTime = [NSDate date];
	self.updating = NO;
	
	// Activate the display link
    CVDisplayLinkStart(_displayLink);
}

-(CVReturn)displayLinkOutputHandler:(CVDisplayLinkRef)displayLink
								now:(const CVTimeStamp*) now
						 outputTime:(const CVTimeStamp*) outputTime
							flagsIn:(CVOptionFlags)flagsIn
						   flagsOut:(CVOptionFlags*) flagsOut{
	if(!self.updating){
		self.updating = YES;
		dispatch_async(dispatch_get_main_queue(), ^{
			[self updateFrameHandler];
			self.updating = NO;
		});
	}
	return kCVReturnSuccess;
}


-(void)updateFrameHandler{
	self.frameCount++;
	self.fpsFrameCount++;
	
	NSDate * now = [NSDate date];
	if([now timeIntervalSinceDate:self.fpsCountStartTime] >= 1.0){
		self.fpsCountStartTime = now;
		self.actualFps = self.fpsFrameCount;
		self.fpsFrameCount = 0;
		ARWLogInfo(@"fps %d",self.actualFps);
	}
	double deltaTime = [now timeIntervalSinceDate:self.prevUpdateTime];
	self.prevUpdateTime = now;
	
	[self.openGLContext makeCurrentContext];
	[self.delegate glView:self updateWithDeltaTime:deltaTime];
	[NSOpenGLContext clearCurrentContext];
}




@end
