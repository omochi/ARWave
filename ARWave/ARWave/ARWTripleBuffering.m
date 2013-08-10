//
//  ARWCycleBuffering.m
//  ARWave
//
//  Created by おもちメタル on 2013/08/10.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#import "ARWTripleBuffering.h"

@interface ARWTripleBuffering()
@property(nonatomic,strong)NSMutableArray * buffers;
//0: フロント直前のを更新中、まだ読めるデータは無い
//1: 予備を更新中、0がいつでも出せる
@property(nonatomic,assign)int backIndex;
@property(nonatomic,strong)NSRecursiveLock * mutex;
@end

@implementation ARWTripleBuffering

-(id)initWithBufferCreator:(id (^)())creator{
	self = [super init];
	if(self){
		_mutex = [[NSRecursiveLock alloc]init];
		_buffers = [[NSMutableArray alloc]init];
		for(int i=0;i<3;i++){
			[_buffers addObject:creator()];
		}
		_backIndex = 1;
	}
	return self;
}

//reader
-(void)swap{
	@synchronized(self){
		//書き込み終わるのを待機
		if(self.backIndex == 1)[self.mutex lock];
		
		id temp = self.buffers[0];
		self.buffers[0] = self.buffers[1];
		self.buffers[1] = self.buffers[2];
		self.buffers[2] = temp;
		
		if(self.backIndex == 1)[self.mutex unlock];
		self.backIndex = 1;
	}
}

-(id)front{
	@synchronized(self){
		return self.buffers[0];
	}
}

-(void)lock{
	@synchronized(self){
		[self.mutex lock];
	}
}
-(void)unlock{
	@synchronized(self){
		if(self.backIndex == 2){
			id temp = self.buffers[1];
			self.buffers[1] = self.buffers[2];
			self.buffers[2] = temp;
		}
		self.backIndex = 2;
		[self.mutex unlock];
	}
}

-(id)back{
	@synchronized(self){
		return self.buffers[self.backIndex];
	}
}



@end
