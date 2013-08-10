//
//  ARWGLView.h
//  ARWave
//
//  Created by おもちメタル on 2013/08/11.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ARWGLView;

@protocol ARWGLViewDelegate <NSObject>

-(void)glViewDidUpdate:(ARWGLView *)glView;

@end

@interface ARWGLView : NSOpenGLView

@property(nonatomic,weak)id<ARWGLViewDelegate> delegate;

@end
