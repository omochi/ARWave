//
//  ARWError.h
//  ARWave
//
//  Created by おもちメタル on 2013/08/07.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ARWPPMacro.h"

extern NSString * const ARWErrorDomain;

extern NSString * const ARWErrorException;
extern NSString * const ARWGLErrorException;


typedef enum ARWErrorCode{
	ARWErrorNoError = 0,
	ARWErrorNotFoundCamera
}ARWErrorCode;

//自動挿入
static NSString * ARWErrorCodeDescription(ARWErrorCode code){
	switch (code) {
		case ARWErrorNoError:
			return @"no error";
		case ARWErrorNotFoundCamera:
			return @"camera not found";
		default:return @"";
	}
}

NSString * ARWErrorDump(NSError * error);

ARWVAFormatFunc3Decl(NSError*,ARWErrorMakeWithDomain,NSString*,domain,NSInteger,code,NSError*,causer);

ARWVAFormatFunc2Decl(NSError*,ARWErrorMake,ARWErrorCode,code,NSError*,causer);

BOOL ARWErrorIs(NSError *error,NSString * domain,NSInteger code);

ARWVAFormatFunc1Decl(NSException*,ARWExceptionMake,NSString *,name);
ARWVAFormatFuncDecl(NSException*,ARWGenericExceptionMake);

NSException * ARWExceptionMakeWithError(NSError * error);

