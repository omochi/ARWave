//
//  ARWGLUtil.h
//  ARWave
//
//  Created by おもちメタル on 2013/08/07.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

#import "ARWEnv.h"
#import "ARWPPMacro.h"
#import "ARWError.h"

NSString * ARWGLGetError(NSString *op);

#if ARW_ENV_BUILD_DEBUG
#define ARWGLAssert(op,...) _ARWGLAssert(op,##__VA_ARGS__)
#else
#define ARWGLAssert(op,...)
#endif

ARWVAFormatFuncDecl(void,_ARWGLAssert);

#define ARWGLCall(funcName,...) ({\
	funcName(__VA_ARGS__);\
	ARWGLAssert(@"%s,%d,%s"__FILE__,__LINE__,#funcName);\
})

#define ARWGLCallRet(retType,funcName,...) ({\
	retType ret = funcName(__VA_ARGS__);\
	ARWGLAssert(@"%s,%d,%s"__FILE__,__LINE__,#funcName);\
	ret;\
})

