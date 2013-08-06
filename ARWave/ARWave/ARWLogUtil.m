//
//  ARWLogUtil.m
//  ARWave
//
//  Created by おもちメタル on 2013/08/06.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#import "ARWLogUtil.h"

static void _ARWLogOutputv(FILE * fp,NSString *format,va_list ap){
	NSString * str = [[NSString alloc]initWithFormat:format arguments:ap];
	fputs([str UTF8String],fp);
	fputs("\n",fp);
}

ARWVAFuncDefVoid(_ARWLogInfo);
void _ARWLogInfov(NSString * format,va_list ap){
	_ARWLogOutputv(stdout,format,ap);
}

ARWVAFuncDefVoid(_ARWLogError);
void _ARWLogErrorv(NSString * format,va_list ap){
	_ARWLogOutputv(stderr,format,ap);
}