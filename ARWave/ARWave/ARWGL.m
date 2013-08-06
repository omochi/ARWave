//
//  ARWGLUtil.m
//  ARWave
//
//  Created by おもちメタル on 2013/08/07.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#import "ARWGL.h"

NSString * ARWGLGetError(NSString *op){
	NSMutableString * result = nil;
	GLenum errorCode;
	while((errorCode = glGetError()) != GL_NO_ERROR){
		if(!result){
			result = [NSMutableString stringWithFormat:@"[GLError] %@: ",op];
		}
		[result appendFormat:@"%s(0x%04x) ",gluErrorString(errorCode),errorCode];
	}
	return result;
}

ARWVAFormatFuncDefVoid(_ARWGLAssert){
	NSString * op = [[NSString alloc]initWithFormat:format arguments:ap];
	NSString * error = ARWGLGetError(op);
	if(error){
		@throw ARWExceptionMake(ARWGLErrorException,@"%@",error);
	}
}
