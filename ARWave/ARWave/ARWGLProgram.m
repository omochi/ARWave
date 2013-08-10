//
//  ARWGLProgram.m
//  ARWave
//
//  Created by おもちメタル on 2013/08/10.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#import "ARWGLProgram.h"

#import "ARWError.h"

@interface ARWGLProgram()
@property(nonatomic,assign)GLuint objId;

@property(nonatomic,strong)ARWGLShader * vertexShader;
@property(nonatomic,strong)ARWGLShader * fragmentShader;

@end

@implementation ARWGLProgram

-(id)initWithVertexShaderSource:(NSString *)vertexShaderSource
		   fragmentShaderSource:(NSString *)fragmentShaderSource{
	return [self initWithVertexShader:[[ARWGLShader alloc]initWithType:GL_VERTEX_SHADER
																source:vertexShaderSource]
					   fragmentShader:[[ARWGLShader alloc]initWithType:GL_FRAGMENT_SHADER
																source:fragmentShaderSource]];
}

-(id)initWithVertexShader:(ARWGLShader *)vertexShader fragmentShader:(ARWGLShader *)fragmentShader{
	self = [super init];
	if(self){
		_objId = ARWGLCallRet(GLuint,glCreateProgram);
		if(!_objId)@throw ARWGenericExceptionMake(@"glCreateProgram failed");
		
		ARWGLCall(glAttachShader,_objId, vertexShader.objId);
		ARWGLCall(glAttachShader,_objId, fragmentShader.objId);
		
		ARWGLCall(glLinkProgram,_objId);
		int status;
		ARWGLCall(glGetProgramiv,_objId, GL_LINK_STATUS, &status);
		if(!status){
			@throw ARWGenericExceptionMake(@"glLinkProgram failed: %@",[self infoLog]);
		}
		
	}
	return self;
}

-(void)dealloc{
	ARWGLCall(glDeleteProgram,_objId);
}

-(NSString *)infoLog{
	int logLength;
	ARWGLCall(glGetProgramiv,_objId, GL_INFO_LOG_LENGTH, &logLength);
	if(logLength==0){
		//ログ無し
		return nil;
	}
	
	char * buf = malloc(logLength);
	ARWGLCall(glGetProgramInfoLog,_objId,logLength,NULL,buf);
	NSString * result = [NSString stringWithCString:buf encoding:NSUTF8StringEncoding];
	free(buf);
	
	return result;
}

-(void)use{
	ARWGLCall(glUseProgram,_objId);
}

@end
