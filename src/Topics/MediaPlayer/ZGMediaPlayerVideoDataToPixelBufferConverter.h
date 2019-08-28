//
//  ZGMediaPlayerVideoDataToPixelBufferConverter.h
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/8/23.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_MediaPlayer

#import <Foundation/Foundation.h>
#import "ZGDemoExternalVideoCaptureControllerProtocol.h"

#if TARGET_OS_OSX
#import <ZegoLiveRoomOSX/zego-api-mediaplayer-oc.h>
#elif TARGET_OS_IOS
#import <ZegoLiveRoom/zego-api-mediaplayer-oc.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@class ZGMediaPlayerVideoDataToPixelBufferConverter;

typedef void(^ZGMediaPlayerVideoDataToPixelBufferConvertCompletion)(ZGMediaPlayerVideoDataToPixelBufferConverter *converter, CVPixelBufferRef buffer, CMTime timestamp);

/**
 视频数据转换成 CVPixelBufferRef 的转换器
 */
@interface ZGMediaPlayerVideoDataToPixelBufferConverter : NSObject

/**
 将播放器播放的数据塞给 converter 处理，处理完成后通过 completion 回调输出 CVPixelBufferRef。
 */
- (void)convertToPixelBufferWithVideoData:(const char *)data size:(int)size format:(ZegoMediaPlayerVideoDataFormat)format completion:(ZGMediaPlayerVideoDataToPixelBufferConvertCompletion)completion;

@end

NS_ASSUME_NONNULL_END
#endif
