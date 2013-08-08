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
		  internalFormat:(GLenum)internalFormat format:(GLenum)format type:(GLenum)type data:(void *)data;

@end
