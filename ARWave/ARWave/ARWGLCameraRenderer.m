//
//  ARWGLCameraRenderer.m
//  ARWave
//
//  Created by おもちメタル on 2013/08/10.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#import "ARWGLCameraRenderer.h"

#import "ARWPPMacro.h"

@interface ARWGLCameraRenderer(){
	GLint _yTextureLoc;
	GLint _uvTextureLoc;
}
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
								  gl_TexCoord[1] = gl_MultiTexCoord1;
							  }
							  )		  
					fragmentShaderSource:
					@"#version 120\n"
					@ARWPPStr(
							  uniform sampler2D yTexture;
							  uniform sampler2D uvTexture;
							  
							  void main(void){
								  mat3 y2r = mat3(+1.164,+1.164,+1.164,
												  +0.000,-0.391,+2.018,
												  +1.596,-0.813,+0.000);
								  vec3 offset = vec3(-0.871,+0.529,-1.082);
								  
								  float colorY = texture2D(yTexture,gl_TexCoord[0].st).r;
								  vec2 colorUv = texture2D(uvTexture,gl_TexCoord[1].st).ra;
								  vec3 colorYuv = vec3(colorY,colorUv.x,colorUv.y);
								  vec3 colorRgb = y2r * colorYuv + offset;
								  gl_FragColor = vec4(colorRgb,1);
							  }
							  )];
		_yTextureLoc = ARWGLCallRet(GLint,glGetUniformLocation,_program.objId,"yTexture");
		_uvTextureLoc = ARWGLCallRet(GLint,glGetUniformLocation,_program.objId,"uvTexture");
	}
	return self;
}

-(void)renderWithYTexture:(ARWGLTexture *)yTexture uvTexture:(ARWGLTexture *)uvTexture vFlip:(BOOL)vFlip{
	float vertices[] = {
		-1.f,+1.f,0.f,  0.f,vFlip ? 0.f : 1.f,
		-1.f,-1.f,0.f,  0.f,vFlip ? 1.f : 0.f,
		+1.f,-1.f,0.f,  1.f,vFlip ? 1.f : 0.f,
		+1.f,+1.f,0.f,  1.f,vFlip ? 0.f : 1.f
	};
	uint16_t indices[] = {
		0,1,3,2
	};
	
	[_program use];
	
	ARWGLCall(glUniform1i,_yTextureLoc,0);
	ARWGLCall(glUniform1i,_uvTextureLoc,1);
	
	ARWGLCall(glActiveTexture,GL_TEXTURE0 + 0);
	ARWGLCall(glEnable,GL_TEXTURE_2D);
	[yTexture apply];
	
	ARWGLCall(glActiveTexture,GL_TEXTURE0 + 1);
	ARWGLCall(glEnable,GL_TEXTURE_2D);
	[uvTexture apply];
	
	ARWGLCall(glEnableClientState,GL_VERTEX_ARRAY);
	ARWGLCall(glVertexPointer,3,GL_FLOAT,sizeof(float)*5,vertices + 0);
	
	ARWGLCall(glClientActiveTexture,GL_TEXTURE0 + 0);
	ARWGLCall(glEnableClientState,GL_TEXTURE_COORD_ARRAY);
	ARWGLCall(glTexCoordPointer,2,GL_FLOAT,sizeof(float)*5,vertices + 3);
	
	ARWGLCall(glClientActiveTexture,GL_TEXTURE0 + 1);
	ARWGLCall(glEnableClientState,GL_TEXTURE_COORD_ARRAY);
	ARWGLCall(glTexCoordPointer,2,GL_FLOAT,sizeof(float)*5,vertices + 3);
	
	ARWGLCall(glDrawElements,GL_TRIANGLE_STRIP,4,GL_UNSIGNED_SHORT,indices);
	
	ARWGLCall(glClientActiveTexture,GL_TEXTURE0 + 1);
	ARWGLCall(glDisableClientState,GL_TEXTURE_COORD_ARRAY);
	
	//最後にゼロ
	ARWGLCall(glClientActiveTexture,GL_TEXTURE0 + 0);
	ARWGLCall(glDisableClientState,GL_TEXTURE_COORD_ARRAY);
	
	ARWGLCall(glDisableClientState,GL_VERTEX_ARRAY);
	
	ARWGLCall(glActiveTexture,GL_TEXTURE0 + 1);
	ARWGLCall(glDisable,GL_TEXTURE_2D);
	
	//最後にゼロ
	ARWGLCall(glActiveTexture,GL_TEXTURE0 + 0);
	ARWGLCall(glDisable,GL_TEXTURE_2D);
	
	ARWGLCall(glUseProgram,0);
}

@end
