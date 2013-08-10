//
//  ARWGLTexture.h
//  ARWave
//
//  Created by おもちメタル on 2013/08/09.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#import "ARWGL.h"

@interface ARWGLTexture : NSObject

-(GLuint)objId;
-(uint32_t)width;
-(uint32_t)height;

-(id)init;

-(void)bind;

-(void)setImageWithWidth:(uint32_t)width height:(uint32_t)height
		  internalFormat:(GLenum)internalFormat;
-(void)setSubImageWithFormat:(GLenum)format type:(GLenum)type data:(const void *)data;

-(void)setMinFiler:(GLenum)minFiler;
-(void)setMagFiler:(GLenum)magFiler;
-(void)setWrapS:(GLenum)wrapS;
-(void)setWrapT:(GLenum)wrapT;

@end
