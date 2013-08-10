//
//  ARWImageFormat.h
//  ARWave
//
//  Created by おもちメタル on 2013/08/10.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum ARWImageFormat{
	ARWImageFormatYUV420
}ARWImageFormat;

static NSString * ARWImageFormatToString(ARWImageFormat format){
	switch (format) {
		case ARWImageFormatYUV420:
			return @"YUV420";
		default:
			return nil;
	}
}