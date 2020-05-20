//
//  ZGDemoExternalVideoCaptureFactory.h
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/8/15.
//  Copyright © 2019 Zego. All rights reserved.
//
#if defined(_Module_ExternalVideoCapture) || defined(_Module_MediaPlayer)
// mediaplayer 专题也用到了外部滤镜

#import <Foundation/Foundation.h>

#if TARGET_OS_OSX
#import <ZegoLiveRoomOSX/zego-api-external-video-capture-oc.h>
#elif TARGET_OS_IOS
#import <ZegoLiveRoom/zego-api-external-video-capture-oc.h>
//#import <ZegoLiveRoom/ZegoVideoCapture.h>
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 示例 Demo 的外部视频采集 factory
 */
@interface ZGDemoExternalVideoCaptureFactory : NSObject <ZegoVideoCaptureFactory>

/**
 准备开始预览的回调。回调中可以真正去实现开启预览，返回是否开启预览。
 */
@property (nonatomic, copy) BOOL(^onStartPreview)(void);

/**
 准备开始采集的回调。回调中可以真正去实现采集，返回是否开启采集。
 */
@property (nonatomic, copy) BOOL(^onStartCapture)(void);

/**
 准备停止预览的回调
 */
@property (nonatomic, copy) void(^onStopPreview)(void);

/**
 准备停止采集的回调
 */
@property (nonatomic, copy) void(^onStopCapture)(void);

@property (nonatomic, readonly) BOOL isPreview;
@property (nonatomic, readonly) BOOL isCapture;

/**
 将视频帧数据塞给 SDK
 
 @param image 采集到的视频数据
 @param time 采集时间戳
 */
- (void)postCapturedData:(CVImageBufferRef)image withPresentationTimeStamp:(CMTime)time;


@end

NS_ASSUME_NONNULL_END

#endif
