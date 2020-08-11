//
//  ZGVideoCaptureForMediaPlayer.h
//  LiveRoomPlayground
//
//  Copyright © 2018年 Zego. All rights reserved.
//

#ifdef _Module_MediaPlayer

#import <Foundation/Foundation.h>

#if TARGET_OS_OSX
#import <ZegoLiveRoomOSX/zego-api-mediaplayer-oc.h>
#import <ZegoLiveRoomOSX/zego-api-external-video-capture-oc.h>
#elif TARGET_OS_IOS
#import <ZegoLiveRoom/zego-api-mediaplayer-oc.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface ZGVideoCaptureForMediaPlayer : NSObject <ZegoVideoCaptureFactory, ZegoMediaPlayerVideoPlayWithIndexDelegate>

@end

NS_ASSUME_NONNULL_END

#endif
