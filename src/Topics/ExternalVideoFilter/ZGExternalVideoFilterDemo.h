//
//  ZGExternalVideoFilterDemo.h
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/7/19.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoFilter

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ZGExternalVideoFilterDemoProtocol <NSObject>

- (ZGView *)getPlaybackView;

@optional

- (void)onExternalVideoFilterPublishStateUpdate:(NSString *)state;
- (void)onExternalVideoFilterPublishQualityUpdate:(NSString *)state;

- (void)onExternalVideoFilterPlayStateUpdate:(NSString *)state;
- (void)onExternalVideoFilterPlayQualityUpdate:(NSString *)state;

@end


@interface ZGExternalVideoFilterDemo : NSObject

@property (nonatomic, weak) id <ZGExternalVideoFilterDemoProtocol>delegate;

/**
 初始化外部滤镜工厂对象
 
 @param type 视频缓冲区类型（Async, Sync, I420, NV12）
 @discussion 创建外部滤镜工厂对象后，先释放 ZegoLiveRoomSDK 确保 setVideoFilterFactory:channelIndex: 的调用在 initSDK 前
 */
- (void)initFilterFactoryType:(ZegoVideoBufferType)type;

- (void)initSDKWithRoomID:(NSString *)roomID streamID:(NSString *)streamID isAnchor:(BOOL)isAnchor;
- (void)loginRoom;
- (void)logoutRoom;
- (void)startPreview;
- (void)stopPreview;
- (void)startPublish;
- (void)stopPublish;
- (void)startPlay;
- (void)stopPlay;
- (void)enablePreviewMirror:(BOOL)enable;

@end

NS_ASSUME_NONNULL_END

#endif
