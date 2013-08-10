//
//  ARWGLCameraRenderer.m
//  ARWave
//
//  Created by おもちメタル on 2013/08/10.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#import "ARWGLCameraRenderer.h"

#import "ARWPPMacro.h"

@interface ARWGLCameraRenderer()
@property(nonatomic,strong)ARWGLProgram * program;
@end

@implementation ARWGLCameraRenderer

-(id)init{
	self = [super init];
	if(self){
		_program = [[ARWGLProgram alloc]
					initWithVertexShaderSource:
					@ARWPPStr(
							  void main(void){
								  gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
								  gl_TexCoord[0] = gl_MultiTexCoord0;
							  }
							  )		  
					fragmentShaderSource:
					@ARWPPStr(
							  uniform sampler2D tex0;
							  void main(void){
								  gl_FragColor = texture2D(tex0, gl_TexCoord[0].st);
							  }
							  )];
		
	}
	return self;
}

-(void)render:(ARWGLTexture *)texture{
	static float vertices[] = {
		-1.f,+1.f,0.f,  0.f,0.f,
		-1.f,-1.f,0.f,  0.f,1.f,
		+1.f,-1.f,0.f,  1.f,1.f,
		+1.f,+1.f,0.f,  1.f,0.f
	};
	static uint16_t indices[] = {
		0,1,3,2
	};
	
	[_program use];
	[texture bind];
	
	ARWGLCall(glEnable,GL_TEXTURE_2D);
	
	ARWGLCall(glEnableClientState,GL_VERTEX_ARRAY);
	ARWGLCall(glEnableClientState,GL_TEXTURE_COORD_ARRAY);
	
	ARWGLCall(glVertexPointer,3,GL_FLOAT,sizeof(float)*5,vertices + 0);
	ARWGLCall(glTexCoordPointer,2,GL_FLOAT,sizeof(float)*5,vertices + 3);
	
	ARWGLCall(glDrawElements,GL_TRIANGLE_STRIP,4,GL_UNSIGNED_SHORT,indices);
	
	ARWGLCall(glDisableClientState,GL_TEXTURE_COORD_ARRAY);
	ARWGLCall(glDisableClientState,GL_VERTEX_ARRAY);
	
	ARWGLCall(glDisable,GL_TEXTURE_2D);
	
}

@end
