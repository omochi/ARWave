//
//  ARWFourCharCode.m
//  ARWave
//
//  Created by おもちメタル on 2013/08/10.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#import "ARWFourCharCode.h"

NSString * ARWFourCharCodeToString(FourCharCode fcc){
	return [NSString stringWithFormat:@"%c%c%c%c",
			 fcc >> 24,
			(fcc >> 16) & 0xFF,
			(fcc >> 8) & 0xFF,
			fcc & 0xFF];
}