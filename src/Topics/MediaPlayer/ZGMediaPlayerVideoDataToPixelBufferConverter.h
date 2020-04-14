//
//  ZGMediaPlayerVideoDataToPixelBufferConverter.h
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/8/23.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_MediaPlayer

#import <Foundation/Foundation.h>

#if TARGET_OS_OSX
#import <ZegoLiveRoomOSX/zego-api-mediaplayer-oc.h>
#elif TARGET_OS_IOS
#import <ZegoLiveRoom/zego-api-mediaplayer-oc.h>
#endif

@class ZGMediaPlayerVideoDataToPixelBufferConverter;

typedef void(^ZGMediaPlayerVideoDataToPixelBufferConvertCompletion)(ZGMediaPlayerVideoDataToPixelBufferConverter *converter, CVPixelBufferRef buffer, CMTime timestamp);

/**
 播放器视频数据转换成 CVPixelBufferRef 的转换器
 */
@interface ZGMediaPlayerVideoDataToPixelBufferConverter : NSObject

/**
 将播放器播放的RGB类型数据塞给 converter 处理，处理完成后通过 completion 回调输出 CVPixelBufferRef。
 */
- (void)convertRGBCategoryDataToPixelBufferWithVideoData:(const char *)data size:(int)size format:(struct ZegoMediaPlayerVideoDataFormat)format completion:(ZGMediaPlayerVideoDataToPixelBufferConvertCompletion)completion;

/**
 将播放器播放的YUV类型数据塞给 converter 处理，处理完成后将在另一线程中通过 completion 回调输出 CVPixelBufferRef。
 */
- (void)convertYUVCategoryDataToPixelBufferWithVideoData:(const char **)data size:(int*)size format:(struct ZegoMediaPlayerVideoDataFormat)format completion:(ZGMediaPlayerVideoDataToPixelBufferConvertCompletion)completion;

@end

#endif
