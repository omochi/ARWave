//
//  ARWAppDelegate.h
//  ARWave
//
//  Created by おもちメタル on 2013/08/06.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreVideo/CoreVideo.h>


@interface ARWAppDelegate : NSObject <NSApplicationDelegate,NSWindowDelegate>

@property (assign) IBOutlet NSWindow *window;

@property(nonatomic,strong) IBOutlet NSOpenGLView * glView;


@end
