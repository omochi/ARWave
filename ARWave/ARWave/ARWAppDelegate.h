//
//  ARWAppDelegate.h
//  ARWave
//
//  Created by おもちメタル on 2013/08/06.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreVideo/CoreVideo.h>
#import <AVFoundation/AVFoundation.h>
#import <ExceptionHandling/ExceptionHandling.h>


@interface ARWAppDelegate : NSObject <NSApplicationDelegate,NSWindowDelegate>

-(CVReturn)displayLinkOutputHandler:(CVDisplayLinkRef)displayLink
								now:(const CVTimeStamp*)now
						 outputTime:(const CVTimeStamp*)outputTime
							flagsIn:(CVOptionFlags)flagsIn
						   flagsOut:(CVOptionFlags*)flagsOut;

@end
