//
//  ZGVideoCaptureForMediaPlayer.h
//  LiveRoomPlayground
//
//  Copyright © 2018年 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZGManager.h"

#if TARGET_OS_OSX
#import <ZegoLiveRoomOSX/zego-api-mediaplayer-oc.h>
#elif TARGET_OS_IOS
#import <ZegoLiveRoom/zego-api-mediaplayer-oc.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface ZGVideoCaptureForMediaPlayer : NSObject <ZegoVideoCaptureFactory, ZegoMediaPlayerVideoPlayDelegate>

@end

NS_ASSUME_NONNULL_END
