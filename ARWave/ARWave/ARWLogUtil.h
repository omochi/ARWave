//
//  ARWLogUtil.h
//  ARWave
//
//  Created by おもちメタル on 2013/08/06.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ARWPPMacro.h"

#define ARWLogInfo(format,...) _ARWLogInfo(format,##__VA_ARGS__)
#define ARWLogError(foramt,...) _ARWLogError(format,##__VA_ARGS__)

ARWVAFuncDecl(void,_ARWLogInfo);
void _ARWLogInfov(NSString * format,va_list ap);

ARWVAFuncDecl(void,_ARWLogError);
void _ARWLogErrorv(NSString * format,va_list ap);
