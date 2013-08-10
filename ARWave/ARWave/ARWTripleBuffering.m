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
@property(nonatomic,strong)NSRecursiveLock * swapMutex;
@property(nonatomic,strong)NSRecursiveLock * writeMutex;
@end

@implementation ARWTripleBuffering

-(id)initWithBufferCreator:(id (^)())creator{
	self = [super init];
	if(self){
		_swapMutex = [[NSRecursiveLock alloc]init];
		_writeMutex = [[NSRecursiveLock alloc]init];
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
	[self.swapMutex lock];
	
	//書き込み終わるのを待機
	if(self.backIndex == 1){
		[self.swapMutex unlock];
		[self.writeMutex lock];
		[self.swapMutex lock];
		[self.writeMutex unlock];
	}
	
	id temp = self.buffers[0];
	self.buffers[0] = self.buffers[1];
	self.buffers[1] = self.buffers[2];
	self.buffers[2] = temp;
	
	if(self.backIndex == 1){
		//[self.writeMutex unlock];
	}
	self.backIndex = 1;
	
	[self.swapMutex unlock];
}

-(id)front{
	id result = nil;
	[self.swapMutex lock];
	result = self.buffers[0];
	[self.swapMutex unlock];
	return result;
}

-(id)lock{
	id result = nil;
	
	[self.swapMutex lock];
	[self.writeMutex lock];
	result = self.buffers[self.backIndex];
	[self.swapMutex unlock];
	return result;
}
-(void)unlock{
	[self.swapMutex lock];
	if(self.backIndex == 2){
		id temp = self.buffers[1];
		self.buffers[1] = self.buffers[2];
		self.buffers[2] = temp;
	}
	self.backIndex = 2;
	[self.writeMutex unlock];
	[self.swapMutex unlock];

}



@end
