//
//  ARWCycleBuffering.h
//  ARWave
//
//  Created by おもちメタル on 2013/08/10.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ARWTripleBuffering : NSObject

-(id)initWithBufferCreator:(id (^)())creator;

//reader

//最新のデータをフロントに持ってくる
-(void)swap;
//最新のデータ
-(id)front;


//writer

//書き込みの準備
-(void)lock;
-(void)unlock;
//書き込み先
-(id)back;

@end
