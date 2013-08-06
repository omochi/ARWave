//
//  ARWCommon.h
//  ARWave
//
//  Created by おもちメタル on 2013/08/07.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#ifdef __APPLE__
#	if DEBUG
#		define ARW_ENV_BUILD_DEBUG (1)
#	else
#		define ARW_ENV_BUILD_DEBUG (0)
#	endif
#endif

#ifndef ARW_ENV_BUILD_DEBUG
#define ARW_ENV_BUILD_DEBUG (1)
#endif

