//
//  ARWGLProgram.h
//  ARWave
//
//  Created by おもちメタル on 2013/08/10.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#import "ARWGL.h"

#import "ARWGLShader.h"

@interface ARWGLProgram : NSObject

-(id)initWithVertexShaderSource:(NSString *)vertexShaderSource
		   fragmentShaderSource:(NSString *)fragmentShaderSource;

-(id)initWithVertexShader:(ARWGLShader *)vertexShader
		   fragmentShader:(ARWGLShader *)fragmentShader;

-(GLuint)objId;
-(NSString *)infoLog;

-(void)use;

@end
