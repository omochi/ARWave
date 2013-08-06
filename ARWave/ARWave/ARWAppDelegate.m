//
//  ARWAppDelegate.m
//  ARWave
//
//  Created by おもちメタル on 2013/08/06.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#import "ARWAppDelegate.h"
#import "ARWGLView.h"
#import "ARWLib.h"

@interface ARWAppDelegate(ARWGLViewDelegate)

@end

@implementation ARWAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
}

-(void)windowWillClose:(NSNotification *)notification{
	[[NSApplication sharedApplication]terminate:self];
}

-(void)glView:(ARWGLView *)glView displayUpdateWithTime:(const CVTimeStamp *)time{
	ARWLogInfo(@"%f",time->videoTime / (double)time->videoTimeScale);
	glClearColor(0.f,0.f,0.2f,1.f);
	glClear(GL_COLOR_BUFFER_BIT);
	glSwapAPPLE();
}

@end
