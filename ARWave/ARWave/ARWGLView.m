//
//  ARWGLView.m
//  ARWave
//
//  Created by おもちメタル on 2013/08/11.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#import "ARWGLView.h"

@implementation ARWGLView

-(void)update{
	[super update];
	[self.delegate glViewDidUpdate:self];
}

@end
