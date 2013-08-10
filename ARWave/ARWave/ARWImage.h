//
//  ARWImage.h
//  ARWave
//
//  Created by おもちメタル on 2013/08/10.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ARWImageFormat.h"

@interface ARWImage : NSObject

@property(nonatomic,assign)ARWImageFormat format;
@property(nonatomic,assign)uint32_t width,height;
@property(nonatomic,strong)NSMutableData * data;

@end
