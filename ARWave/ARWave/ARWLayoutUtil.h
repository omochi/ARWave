//
//  ARWRectUtil.h
//  ARWave
//
//  Created by おもちメタル on 2013/08/11.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum ARWLayoutGravity {
	ARWLayoutGravityXLeft = 1,
	ARWLayoutGravityXCenter = 2,
	ARWLayoutGravityXRight = 3,
	ARWLayoutGravityYTop = 1 << 2,
	ARWLayoutGravityYCenter = 2 << 2,
	ARWLayoutGravityYBottom = 3 << 2,
	ARWLayoutGravityCenter = ARWLayoutGravityXCenter | ARWLayoutGravityYCenter,
	
	ARWLayoutGravityXMask = 3,
	ARWLayoutGravityYMask = 3 << 2
} ARWLayoutGravity;

CGRect ARWRectWidthFit(CGRect frame,CGSize content,ARWLayoutGravity gravity);
CGRect ARWRectHeightFit(CGRect frame,CGSize content,ARWLayoutGravity gravity);
CGRect ARWRectAspectFit(CGRect frame,CGSize content,ARWLayoutGravity gravity);
CGRect ARWRectAspectFill(CGRect frame,CGSize content,ARWLayoutGravity gravity);
