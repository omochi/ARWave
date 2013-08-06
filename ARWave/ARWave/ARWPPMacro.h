//
//  ARWPPMacro.h
//  ARWave
//
//  Created by おもちメタル on 2013/08/06.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#pragma once

#define ARWVAFuncDecl(retType,vaFunc) \
retType vaFunc(NSString * format,...) NS_FORMAT_FUNCTION(1,0);

#define ARWVAFuncDefVoid(vaFunc) \
void vaFunc(NSString * format,...){\
	va_list ap;\
	va_start(ap,format);\
	vaFunc##v(format,ap);\
	va_end(ap);\
}
