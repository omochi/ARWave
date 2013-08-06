//
//  ARWError.m
//  ARWave
//
//  Created by おもちメタル on 2013/08/07.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#import "ARWError.h"

NSString * const ARWErrorDomain = @"com.omochimetaru.ARW.ErrorDomain";

NSString * ARWErrorDump(NSError * error){
	NSMutableArray * lines = [NSMutableArray array];
	while(error){
		NSMutableArray * strs = [NSMutableArray array];
		[strs addObject:error.domain];
		[strs addObject:[NSString stringWithFormat:@"0x%04lx",error.code]];
		if([error localizedDescription]){
			[strs addObject:[error localizedDescription]];
		}
		if([error localizedFailureReason]){
			[strs addObject:[error localizedFailureReason]];
		}
		if([error localizedRecoverySuggestion]){
			[strs addObject:[error localizedRecoverySuggestion]];
		}
		[lines addObject:[strs componentsJoinedByString:@": "]];
		
		error = error.userInfo[NSUnderlyingErrorKey];
	}
	return [lines componentsJoinedByString:@"\n"];
}

ARWVAFormatFunc3Def(NSError*,ARWErrorMakeWithDomain,NSString *,domain, NSInteger, code, NSError*, causer){
	NSString * desc = [[NSString alloc]initWithFormat:format arguments:ap];
	NSMutableDictionary *user = [NSMutableDictionary dictionary];
	user[NSLocalizedDescriptionKey] = desc;
	if(causer)user[NSUnderlyingErrorKey] = causer;
	return [NSError errorWithDomain:domain code:code userInfo:user];
}

ARWVAFormatFunc2Def(NSError*,ARWErrorMake,ARWErrorCode,code,NSError*,causer){
	return ARWErrorMakeWithDomainv(ARWErrorDomain,code,causer,format,ap);
}

BOOL ARWErrorIs(NSError *error,NSString * domain,NSInteger code){
	return [error.domain isEqualToString:domain] && error.code == code;
}

ARWVAFormatFunc1Def(NSException*,ARWExceptionMake,NSString*,name){
	return [NSException exceptionWithName:name
								   reason:[[NSString alloc]initWithFormat:format arguments:ap]
								 userInfo:nil];
}

NSException * ARWExceptionMakeWithError(NSError * error){
	return ARWExceptionMake(NSGenericException,@"%@",ARWErrorDump(error));
}