//
//  ARWGLUtil.h
//  ARWave
//
//  Created by おもちメタル on 2013/08/07.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/glu.h>

#import "ARWEnv.h"

NSString * ARWGLGetError(NSString *op);

#if ARW_ENV_BUILD_DEBUG
#define ARWGLAssert(op) _ARWGLAssert(op)
#else
#define ARWGLAssert(op) 
#endif

void _ARWGLAssert(NSString * op);