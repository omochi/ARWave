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

typedef enum ARWErrorCode{
	ARWErrorNoError = 0
}ARWErrorCode;

NSString * ARWErrorDump(NSError * error);

ARWVAFormatFunc3Decl(NSError*,ARWErrorMakeWithDomain,NSString*,domain,NSInteger,code,NSError*,causer);

ARWVAFormatFunc2Decl(NSError*,ARWErrorMake,ARWErrorCode,code,NSError*,causer);

BOOL ARWErrorIs(NSError *error,NSString * domain,NSInteger code);

ARWVAFormatFunc1Decl(NSException*,ARWExceptionMake,NSString *,name);

NSException * ARWExceptionMakeWithError(NSError * error);