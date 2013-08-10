//
//  ARWRectUtil.m
//  ARWave
//
//  Created by おもちメタル on 2013/08/11.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#import "ARWLayoutUtil.h"

CGRect ARWRectWidthFit(CGRect frame,CGSize content,ARWLayoutGravity gravity){
	float w = CGRectGetWidth(frame);
	float h = w * content.height / content.width;
	float x = CGRectGetMinX(frame);
	float y;
	switch (gravity & ARWLayoutGravityYMask) {
		case ARWLayoutGravityYTop:
			y = CGRectGetMinY(frame);
			break;
		case ARWLayoutGravityYBottom:
			y = CGRectGetMaxY(frame) - h;
			break;
		default:
			y = CGRectGetMidY(frame) - h/2.f;
			break;
	}
	return CGRectMake(x, y, w, h);
}

CGRect ARWRectHeightFit(CGRect frame,CGSize content,ARWLayoutGravity gravity){
	float h = CGRectGetHeight(frame);
	float w = h * content.width / content.height;
	float y = CGRectGetMinY(frame);
	float x;
	switch (gravity & ARWLayoutGravityXMask) {
		case ARWLayoutGravityXLeft:
			x = CGRectGetMinX(frame);
			break;
		case ARWLayoutGravityXRight:
			x = CGRectGetMaxX(frame) - w;
			break;
		default:
			x = CGRectGetMidX(frame) - w/2.f;
			break;
	}
	return CGRectMake(x, y, w, h);
}
CGRect ARWRectAspectFit(CGRect frame,CGSize content,ARWLayoutGravity gravity){
	if(content.width * CGRectGetHeight(frame) > CGRectGetWidth(frame) * content.height){
		return ARWRectWidthFit(frame, content, gravity);
	}else{
		return ARWRectHeightFit(frame, content, gravity);
	}
}

CGRect ARWRectAspectFill(CGRect frame,CGSize content,ARWLayoutGravity gravity){
	if(content.width * CGRectGetHeight(frame) > CGRectGetWidth(frame) * content.height){
		return ARWRectHeightFit(frame, content, gravity);
	}else{
		return ARWRectWidthFit(frame, content, gravity);
	}
}
