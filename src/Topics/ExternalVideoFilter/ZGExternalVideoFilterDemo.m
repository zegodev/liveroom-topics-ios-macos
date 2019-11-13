//
//  ZGExternalVideoFilterDemo.m
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/7/19.
//  Copyright © 2019 Zego. All rights reserved.
//


#ifdef _Module_ExternalVideoFilter

#import "ZGExternalVideoFilterDemo.h"
#import "ZGVideoFilterFactoryDemo.h"
#import "ZGAppGlobalConfigManager.h"
#import "ZGAppSignHelper.h"
#import "ZGUserIDHelper.h"
#import "ZGApiManager.h"

#if TARGET_OS_OSX
#import <ZegoLiveRoomOSX/ZegoLiveRoomApi.h>
#elif TARGET_OS_IOS
#import <ZegoLiveRoom/ZegoLiveRoom.h>
#endif


@interface ZGExternalVideoFilterDemo () <ZegoLivePublisherDelegate, ZegoLivePlayerDelegate>

@property (nonatomic, strong) ZegoLiveRoomApi *zegoApi;
@property (nonatomic, copy) NSString *roomID;
@property (nonatomic, copy) NSString *streamID;
@property (nonatomic, assign) BOOL isAnchor;

@property (nonatomic, strong) ZGVideoFilterFactoryDemo *g_filterFactory;

@end

@implementation ZGExternalVideoFilterDemo


- (void)dealloc {
    [self.zegoApi logoutRoom];
    self.zegoApi = nil;
    [self releaseFilterFactory];
}

#pragma mark - 外部滤镜工厂相关方法

/**
 初始化外部滤镜工厂对象
 
 @param type 视频缓冲区类型（Async, Sync, I420, NV12）
 @discussion 创建外部滤镜工厂对象后，先释放 ZegoLiveRoomSDK 确保 setVideoFilterFactory:channelIndex: 的调用在 initSDK 前
 */
- (void)initFilterFactoryType:(ZegoVideoBufferType)type {
    if (self.g_filterFactory == nil) {
        self.g_filterFactory = [[ZGVideoFilterFactoryDemo alloc] init];
        self.g_filterFactory.bufferType = type;
    }
    
    [ZGApiManager releaseApi];
    [ZegoExternalVideoFilter setVideoFilterFactory:self.g_filterFactory channelIndex:ZEGOAPI_CHN_MAIN];
}


/**
 释放外部滤镜工厂对象
 */
- (void)releaseFilterFactory {
    self.g_filterFactory = nil;
    // 需要在 initSDK 前调用（所以释放工厂也是在释放SDK后调用）
    [ZegoExternalVideoFilter setVideoFilterFactory:nil channelIndex:ZEGOAPI_CHN_MAIN];
}

#pragma mark - ZegoLiveRoom 的初始化、推拉流相关

- (void)initSDKWithRoomID:(NSString *)roomID streamID:(NSString *)streamID isAnchor:(BOOL)isAnchor {
    self.roomID = roomID;
    self.streamID = streamID;
    self.isAnchor = isAnchor;
    
    ZGAppGlobalConfig *appConfig = [[ZGAppGlobalConfigManager sharedInstance] globalConfig];
    // 设置环境
    [ZegoLiveRoomApi setUseTestEnv:(appConfig.environment == ZGAppEnvironmentTest)];
    // 设置硬编硬解
    [ZegoLiveRoomApi requireHardwareEncoder:appConfig.openHardwareEncode];
    [ZegoLiveRoomApi requireHardwareDecoder:appConfig.openHardwareDecode];
    
    self.zegoApi = [[ZegoLiveRoomApi alloc] initWithAppID:(unsigned int)appConfig.appID appSignature:[ZGAppSignHelper convertAppSignFromString:appConfig.appSign] completionBlock:^(int errorCode) {
        if (errorCode == 0) {
            ZGLogInfo(@"初始化 SDK 成功");
        } else {
            ZGLogError(@"初始化 SDK 失败，错误码：%d", errorCode);
        }
    }];
    
    if (self.zegoApi) {
        ZegoAVConfig *avConfig = [ZegoAVConfig presetConfigOf:ZegoAVConfigPreset_Veryhigh];
        [self.zegoApi setAVConfig:avConfig];
        [self.zegoApi setPublisherDelegate:self];
        [self.zegoApi setPlayerDelegate:self];
    }
}

- (void)loginRoom {
    NSString *userID = ZGUserIDHelper.userID;
    [ZegoLiveRoomApi setUserID:userID userName:userID];
    
    [self.zegoApi loginRoom:self.roomID role:self.isAnchor ? ZEGO_ANCHOR : ZEGO_AUDIENCE withCompletionBlock:^(int errorCode, NSArray<ZegoStream *> *streamList) {
        if (errorCode == 0) {
            ZGLogInfo(@"登录房间成功");
        } else {
            ZGLogError(@"登录房间失败，错误码：%d", errorCode);
        }
    }];
}

- (void)logoutRoom {
    [self.zegoApi logoutRoom];
}

- (void)startPreview {
    if ([self.delegate respondsToSelector:@selector(getPlaybackView)]) {
        [self.zegoApi setPreviewView:[self.delegate getPlaybackView]];
//        [self.zegoApi setPreviewViewMode:ZegoVideoViewModeScaleAspectFill];
        [self.zegoApi startPreview];
    } else {
        ZGLogError(@"未设置预览 View");
    }
}

- (void)stopPreview {
    [self.zegoApi stopPreview];
    [self.zegoApi setPreviewView:nil];
    ZGLogInfo(@"停止预览");
}

- (void)startPublish {
    
    [ZegoLiveRoomApi setPublishQualityMonitorCycle:800];
    
    BOOL publishResult = [self.zegoApi startPublishing:self.streamID title:nil flag:ZEGOAPI_SINGLE_ANCHOR];
    if (publishResult) {
        ZGLogInfo(@"推流成功, 房间ID:%@, 流ID:%@", self.roomID, self.streamID);
    } else {
        ZGLogError(@"推流失败, 房间ID:%@, 流ID:%@", self.roomID, self.streamID);
    }
}

- (void)stopPublish {
    [self.zegoApi stopPublishing];
    ZGLogInfo(@"停止推流");
}

- (void)startPlay {
    if ([self.delegate respondsToSelector:@selector(getPlaybackView)]) {
        [ZegoLiveRoomApi setPlayQualityMonitorCycle:800];
        BOOL result = [self.zegoApi startPlayingStream:self.streamID inView:[self.delegate getPlaybackView]];
        if (result) {
            ZGLogInfo(@"拉流成功, 房间ID:%@, 流ID:%@", self.roomID, self.streamID);
            [self.zegoApi setViewMode:ZegoVideoViewModeScaleAspectFill ofStream:self.streamID];
        } else {
            ZGLogError(@"拉流失败, 房间ID:%@, 流ID:%@", self.roomID, self.streamID);
        }
    } else {
        ZGLogError(@"未设置播放的 View");
    }
}

- (void)stopPlay {
    [self.zegoApi stopPlayingStream:self.streamID];
}

- (void)enablePreviewMirror:(BOOL)enable {
    [self.zegoApi setVideoMirrorMode:enable ? ZegoVideoMirrorModePreviewCaptureBothNoMirror : ZegoVideoMirrorModePreviewMirrorPublishNoMirror];
}


#pragma mark - Publisher Delegate

- (void)onPublishStateUpdate:(int)stateCode streamID:(NSString *)streamID streamInfo:(NSDictionary *)info {
    ZGLogInfo(@"推流状态回调:%d, streamID:%@", stateCode, streamID);
    if ([self.delegate respondsToSelector:@selector(onExternalVideoFilterPublishStateUpdate:)]) {
        NSString *stateString = stateCode == 0 ? @"🔵推流中" : [NSString stringWithFormat:@"❗️Error:%d", stateCode];
        [self.delegate onExternalVideoFilterPublishStateUpdate:stateString];
    }
}



- (void)onPublishQualityUpdate:(NSString *)streamID quality:(ZegoApiPublishQuality)quality {
    //    ZGLogInfo(@"推流质量更新：分辨率：%dx%d, 帧率：%ffps, 码率：%fkbps", quality.height, quality.width, quality.fps, quality.kbps);
    if ([self.delegate respondsToSelector:@selector(onExternalVideoFilterPublishQualityUpdate:)]) {
        NSString *qualityString = [NSString stringWithFormat:@"分辨率：%dx%d \n帧率：%.2f fps \n码率：%.2f kbps", quality.height, quality.width, quality.fps, quality.kbps];
        [self.delegate onExternalVideoFilterPublishQualityUpdate:qualityString];
    }
}

#pragma mark - Player Delegate

- (void)onPlayStateUpdate:(int)stateCode streamID:(NSString *)streamID {
    ZGLogInfo(@"拉流状态回调:%d, streamID:%@", stateCode, streamID);
    if ([self.delegate respondsToSelector:@selector(onExternalVideoFilterPlayStateUpdate:)]) {
        NSString *stateString = stateCode == 0 ? @"🔵拉流中" : [NSString stringWithFormat:@"❗️Error:%d", stateCode];
        [self.delegate onExternalVideoFilterPlayStateUpdate:stateString];
    }
}


- (void)onPlayQualityUpate:(NSString *)streamID quality:(ZegoApiPlayQuality)quality {
    //    ZGLogInfo(@"拉流质量更新:分辨率:%dx%d, 帧率:%ffps, 码率:%fkbps", quality.height, quality.width, quality.fps, quality.kbps);
    if ([self.delegate respondsToSelector:@selector(onExternalVideoFilterPlayQualityUpdate:)]) {
        NSString *qualityString = [NSString stringWithFormat:@"分辨率：%dx%d \n帧率：%.2f fps \n码率：%.2f kbps", quality.height, quality.width, quality.fps, quality.kbps];
        [self.delegate onExternalVideoFilterPlayQualityUpdate:qualityString];
    }
}




@end

#endif
