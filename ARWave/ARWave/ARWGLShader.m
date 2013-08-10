//
//  ARWGLShader.m
//  ARWave
//
//  Created by おもちメタル on 2013/08/10.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#import "ARWGLShader.h"
#import "ARWError.h"

@interface ARWGLShader()
@property(nonatomic,assign)GLuint objId;
@end

@implementation ARWGLShader

-(id)initWithType:(GLenum)type source:(NSString *)source{
	self = [super init];
	if(self){
		_objId = ARWGLCallRet(GLuint,glCreateShader,type);
		if(!_objId)@throw ARWGenericExceptionMake(@"glCreateShader failed");
		
		const char * csource = [source UTF8String];
		ARWGLCall(glShaderSource,_objId,1,&csource,NULL);
		
		ARWGLCall(glCompileShader,_objId);
		
		int status;
		ARWGLCall(glGetShaderiv,_objId, GL_COMPILE_STATUS, &status);
		if(!status){
			@throw ARWGenericExceptionMake(@"glCompileShader failed: %@",[self infoLog]);
		}
	}
	return self;
}

-(void)dealloc{
	ARWGLCall(glDeleteShader,_objId);
}

-(NSString *)infoLog{
	int logLength;
	ARWGLCall(glGetShaderiv,_objId, GL_INFO_LOG_LENGTH, &logLength);
	if(logLength==0){
		//ログ無し
		return nil;
	}
	
	char * buf = malloc(logLength);
	ARWGLCall(glGetShaderInfoLog,_objId,logLength,NULL,buf);
	NSString * result = [NSString stringWithCString:buf encoding:NSUTF8StringEncoding];
	free(buf);
	
	return result;
}

@end
