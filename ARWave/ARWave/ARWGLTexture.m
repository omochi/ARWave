//
//  ARWGLTexture.m
//  ARWave
//
//  Created by おもちメタル on 2013/08/09.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#import "ARWGLTexture.h"

@interface ARWGLTexture()
@property(nonatomic,assign)GLuint objId;
@property(nonatomic,assign)uint32_t width,height;
@property(nonatomic,assign)GLenum internalFormat;
@end

@implementation ARWGLTexture

-(id)init{
	self = [super init];
	if(self){
		ARWGLCall(glGenTextures,1,&_objId);
		
		[self setMinFiler:GL_LINEAR];
		[self setMagFiler:GL_LINEAR];
		[self setWrapS:GL_CLAMP_TO_EDGE];
		[self setWrapT:GL_CLAMP_TO_EDGE];
	}
	return self;
}

-(void)dealloc{
	ARWGLCall(glDeleteTextures,1,&_objId);
}

-(void)bind{
	ARWGLCall(glBindTexture,GL_TEXTURE_2D,_objId);
}

-(void)setImageWithWidth:(uint32_t)width height:(uint32_t)height
		  internalFormat:(GLenum)internalFormat{
	[self bind];
	
	ARWGLCall(glTexImage2D,GL_TEXTURE_2D,0,internalFormat,width, height, 0,GL_LUMINANCE,GL_UNSIGNED_BYTE, NULL);

	_width = width;
	_height = height;
	_internalFormat = internalFormat;
}

-(void)setSubImageWithFormat:(GLenum)format type:(GLenum)type data:(const void *)data{
	[self bind];
	ARWGLCall(glTexSubImage2D,GL_TEXTURE_2D,0,0,0,_width,_height,format,type,data);
}

-(void)setMinFiler:(GLenum)minFiler{
	[self bind];
	ARWGLCall(glTexParameteri,GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,minFiler);
}
-(void)setMagFiler:(GLenum)magFiler{
	[self bind];
	ARWGLCall(glTexParameteri,GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,magFiler);
}
-(void)setWrapS:(GLenum)wrapS{
	[self bind];
	ARWGLCall(glTexParameteri,GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,wrapS);
}
-(void)setWrapT:(GLenum)wrapT{
	[self bind];
	ARWGLCall(glTexParameteri,GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,wrapT);
}

@end
