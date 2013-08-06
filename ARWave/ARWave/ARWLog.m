//
//  ARWLogUtil.m
//  ARWave
//
//  Created by おもちメタル on 2013/08/06.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#import "ARWLog.h"

static void _ARWLogOutputv(FILE * fp,NSString *format,va_list ap){
	NSString * str = [[NSString alloc]initWithFormat:format arguments:ap];
	fputs([str UTF8String],fp);
	fputs("\n",fp);
}

ARWVAFormatFuncDefVoid(_ARWLogInfo){
	fputs("[INFO]",stdout);
	_ARWLogOutputv(stdout,format,ap);
}

ARWVAFormatFuncDefVoid(_ARWLogError){
	fputs("[ERROR]",stderr);
	_ARWLogOutputv(stderr,format,ap);
}