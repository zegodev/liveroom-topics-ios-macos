//
//  ZegoDefine.h
//  LiveRoomPlayGround
//
//  Created by Sky on 2019/6/10.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifndef ZegoDefine_h
#define ZegoDefine_h

#define Weakify( x ) \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
__weak __typeof__(x) __weak_##x##__ = x; \
_Pragma("clang diagnostic pop")

#define Strongify( x ) \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
__strong __typeof__(x) x = __weak_##x##__; \
_Pragma("clang diagnostic pop") \
if (!self) {return;}

#endif /* ZegoDefine_h */
