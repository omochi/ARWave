//
//  ARWPPMacro.h
//  ARWave
//
//  Created by おもちメタル on 2013/08/06.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#define ARWPPStr(str) #str

#define ARWVAFormatFuncDecl(retType,vaFunc) \
retType vaFunc(NSString * format,...) NS_FORMAT_FUNCTION(1,2); \
retType vaFunc##v(NSString * format,va_list ap) NS_FORMAT_FUNCTION(1,0);

#define ARWVAFormatFunc1Decl(retType,vaFunc,a1Type,a1Name) \
retType vaFunc(a1Type a1Name,NSString * format,...) NS_FORMAT_FUNCTION(2,3); \
retType vaFunc##v(a1Type a1Name,NSString * format,va_list ap) NS_FORMAT_FUNCTION(2,0);

#define ARWVAFormatFunc2Decl(retType,vaFunc,a1Type,a1Name,a2Type,a2Name) \
retType vaFunc(a1Type a1Name,a2Type a2Name,NSString * format,...) NS_FORMAT_FUNCTION(3,4); \
retType vaFunc##v(a1Type a1Name,a2Type a2Name,NSString * format,va_list ap) NS_FORMAT_FUNCTION(3,0);

#define ARWVAFormatFunc3Decl(retType,vaFunc,a1Type,a1Name,a2Type,a2Name,a3Type,a3Name) \
retType vaFunc(a1Type a1Name,a2Type a2Name,a3Type a3Name,NSString * format,...) NS_FORMAT_FUNCTION(4,5); \
retType vaFunc##v(a1Type a1Name,a2Type a2Name,a3Type a3Name,NSString * format,va_list ap) NS_FORMAT_FUNCTION(4,0);

#define ARWVAFormatFuncDefVoid(vaFunc) \
void vaFunc(NSString * format,...){\
	va_list ap;\
	va_start(ap,format);\
	vaFunc##v(format,ap);\
	va_end(ap);\
}\
void vaFunc##v(NSString * format,va_list ap)

#define ARWVAFormatFuncDef(retType,vaFunc) \
retType vaFunc(NSString * format,...){\
	va_list ap;\
	va_start(ap,format);\
	retType ret=vaFunc##v(format,ap);\
	va_end(ap);\
	return ret;\
}\
retType vaFunc##v(NSString * format,va_list ap)

#define ARWVAFormatFunc1DefVoid(vaFunc,a1Type,a1Name) \
void vaFunc(a1Type a1Name,NSString * format,...){\
	va_list ap;\
	va_start(ap,format);\
	vaFunc##v(a1Name,format,ap);\
	va_end(ap);\
}\
void vaFunc##v(a1Type a1Name,NSString * format,va_list ap)

#define ARWVAFormatFunc1Def(retType,vaFunc,a1Type,a1Name) \
retType vaFunc(a1Type a1Name,NSString * format,...){\
	va_list ap;\
	va_start(ap,format);\
	retType ret=vaFunc##v(a1Name,format,ap);\
	va_end(ap);\
	return ret;\
}\
retType vaFunc##v(a1Type a1Name,NSString * format,va_list ap)

#define ARWVAFormatFunc2DefVoid(vaFunc,a1Type,a1Name,a2Type,a2Name) \
void vaFunc(a1Type a1Name,a2Type a2Name,NSString * format,...){\
	va_list ap;\
	va_start(ap,format);\
	vaFunc##v(a1Name,a2Name,format,ap);\
	va_end(ap);\
}\
void vaFunc##v(a1Type a1Name,a2Type a2Name,NSString * format,va_list ap)

#define ARWVAFormatFunc2Def(retType,vaFunc,a1Type,a1Name,a2Type,a2Name) \
retType vaFunc(a1Type a1Name,a2Type a2Name,NSString * format,...){\
	va_list ap;\
	va_start(ap,format);\
	retType ret=vaFunc##v(a1Name,a2Name,format,ap);\
	va_end(ap);\
	return ret;\
}\
retType vaFunc##v(a1Type a1Name,a2Type a2Name,NSString * format,va_list ap)

#define ARWVAFormatFunc3DefVoid(vaFunc,a1Type,a1Name,a2Type,a2Name,a3Type,a3Name) \
void vaFunc(a1Type a1Name,a2Type a2Name,a3Type a3Name,NSString * format,...){\
	va_list ap;\
	va_start(ap,format);\
	vaFunc##v(a1Name,a2Name,a3Name,format,ap);\
	va_end(ap);\
}\
void vaFunc##v(a1Type a1Name,a2Type a2Name,a3Type a3Name,NSString * format,va_list ap)

#define ARWVAFormatFunc3Def(retType,vaFunc,a1Type,a1Name,a2Type,a2Name,a3Type,a3Name) \
retType vaFunc(a1Type a1Name,a2Type a2Name,a3Type a3Name,NSString * format,...){\
	va_list ap;\
	va_start(ap,format);\
	retType ret=vaFunc##v(a1Name,a2Name,a3Name,format,ap);\
	va_end(ap);\
	return ret;\
}\
retType vaFunc##v(a1Type a1Name,a2Type a2Name,a3Type a3Name,NSString * format,va_list ap)
