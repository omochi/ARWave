//
//  ARWGLShader.h
//  ARWave
//
//  Created by おもちメタル on 2013/08/10.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#import "ARWGL.h"

@interface ARWGLShader : NSObject

-(id)initWithType:(GLenum)type source:(NSString *)source;

-(GLuint)objId;

-(NSString *)infoLog;

@end
