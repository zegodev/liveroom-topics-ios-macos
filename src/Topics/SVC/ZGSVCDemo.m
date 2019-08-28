//
//  ZegoSVCDemo.m
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/8/14.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ScalableVideoCoding

#import "ZGSVCDemo.h"
#import "ZGAppGlobalConfigManager.h"
#import "ZGAppSignHelper.h"
#import "ZGUserIDHelper.h"
#if TARGET_OS_OSX
#import <ZegoLiveRoomOSX/ZegoLiveRoomApi.h>
#elif TARGET_OS_IOS
#import <ZegoLiveRoom/ZegoLiveRoom.h>
#endif

@interface ZGSVCDemo () <ZegoLivePublisherDelegate, ZegoLivePlayerDelegate>

@property (nonatomic, strong) ZegoLiveRoomApi *zegoApi;
@property (nonatomic, copy) NSString *roomID;
@property (nonatomic, copy) NSString *streamID;
@property (nonatomic, assign) BOOL isAnchor;

@end

@implementation ZGSVCDemo


- (instancetype)initWithRoomID:(NSString *)roomID streamID:(NSString *)streamID isAnchor:(BOOL)isAnchor {
    self = [super init];
    if (self) {
        self.roomID = roomID;
        self.streamID = streamID;
        self.isAnchor = isAnchor;
        
        // 默认拉流分层选择扩展层（高分辨率）
        self.streamLayerType = StreamLayerTypeExtend;
        
        // 默认开启分层编码
        self.openSVC = YES;
        
        /**
         *** 注意 ***
         调用此接口强制拉流走 UDP
         因为分层编码拉流方切换视频分层的 -activateVideoPlayStream:active:videoLayer: 方法只在 UDP 下生效，CDN 无效
         
         *** 不建议使用该接口 ***
         应当在 AppID 后台控制台里配置拉流默认走 UDP 还是 CDN
         */
        [ZegoLiveRoomApi setConfig:@"prefer_play_ultra_source=1"];
        
        ZGAppGlobalConfig *appConfig = [[ZGAppGlobalConfigManager sharedInstance] globalConfig];
        [ZegoLiveRoomApi setUseTestEnv:(appConfig.environment == ZGAppEnvironmentTest)];
        
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
    return self;
}

- (void)dealloc {
    [self.zegoApi logoutRoom];
    ZGLogInfo(@"退出房间");
    self.zegoApi = nil;
    ZGLogInfo(@"释放SDK");
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
    // 根据 self.openSVC 状态决定是否开启分层编码
    BOOL svcResult = [self.zegoApi setVideoCodecId:self.openSVC ? VIDEO_CODEC_MULTILAYER : VIDEO_CODEC_DEFAULT ofChannel:ZEGOAPI_CHN_MAIN];
    if (svcResult) {
        ZGLogInfo(@"🍏SVC开关状态：%@", self.openSVC ? @"开" : @"关");
    } else {
        ZGLogError(@"🍎SVC开关失败");
    }
    
    // 优化弱网环境的配置
    
    // 设置延迟模式
    [self.zegoApi setLatencyMode:ZEGOAPI_LATENCY_MODE_LOW3];
    // 开启流量控制
    [self.zegoApi enableTrafficControl:YES properties:ZEGOAPI_TRAFFIC_CONTROL_BASIC | ZEGOAPI_TRAFFIC_CONTROL_ADAPTIVE_FPS | ZEGOAPI_TRAFFIC_CONTROL_ADAPTIVE_RESOLUTION];
    
    
    [ZegoLiveRoomApi setPublishQualityMonitorCycle:800];
    
    // 以连麦模式开始推流（混流模式也可以使用分层编码，而单主播模式不行）
    BOOL publishResult = [self.zegoApi startPublishing:self.streamID title:nil flag:ZEGOAPI_JOIN_PUBLISH];
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

// 拉流方切换视频分层（高低分辨率切换）
- (void)switchPlayStreamVideoLayer {
    VideoStreamLayer streamLayer;
    switch (self.streamLayerType) {
        case StreamLayerTypeAuto:
            streamLayer = VideoStreamLayer_Auto;
            break;
        case StreamLayerTypeBase:
            streamLayer = VideoStreamLayer_BaseLayer;
            break;
        case StreamLayerTypeExtend:
            streamLayer = VideoStreamLayer_ExtendLayer;
            break;
    }
    
    int stateCode = [self.zegoApi activateVideoPlayStream:self.streamID active:true videoLayer:streamLayer];
    if (stateCode == 0) {
        NSArray<NSString *> *layerNameArray = @[@"Auto", @"Base", @"Extend"];
        ZGLogInfo(@"🍏切换视频分层至：%@", layerNameArray[streamLayer+1]);
    } else {
        ZGLogError(@"🍎切换视频分层失败");
    }
}


#pragma mark - Publisher Delegate

- (void)onPublishStateUpdate:(int)stateCode streamID:(NSString *)streamID streamInfo:(NSDictionary *)info {
    ZGLogInfo(@"推流状态回调:%d, streamID:%@", stateCode, streamID);
}


- (void)onPublishQualityUpdate:(NSString *)streamID quality:(ZegoApiPublishQuality)quality {
//    ZGLogInfo(@"推流质量更新：分辨率：%dx%d, 帧率：%ffps, 码率：%fkbps", quality.height, quality.width, quality.fps, quality.kbps);
    if ([self.delegate respondsToSelector:@selector(onSVCPublishQualityUpdate:)]) {
        NSString *qualityString = [NSString stringWithFormat:@"分辨率：%dx%d \n帧率：%.2f fps \n码率：%.2f kbps", quality.height, quality.width, quality.fps, quality.kbps];
        [self.delegate onSVCPublishQualityUpdate:qualityString];
    }
}

#pragma mark - Player Delegate

- (void)onPlayStateUpdate:(int)stateCode streamID:(NSString *)streamID {
    ZGLogInfo(@"拉流状态回调:%d, streamID:%@", stateCode, streamID);
}


- (void)onPlayQualityUpate:(NSString *)streamID quality:(ZegoApiPlayQuality)quality {
//    ZGLogInfo(@"拉流质量更新:分辨率:%dx%d, 帧率:%ffps, 码率:%fkbps", quality.height, quality.width, quality.fps, quality.kbps);
    if ([self.delegate respondsToSelector:@selector(onSVCPlayQualityUpdate:)]) {
        NSString *qualityString = [NSString stringWithFormat:@"分辨率：%dx%d \n帧率：%.2f fps \n码率：%.2f kbps", quality.height, quality.width, quality.fps, quality.kbps];
        [self.delegate onSVCPlayQualityUpdate:qualityString];
    }
}


- (void)onVideoSizeChangedTo:(CGSize)size ofStream:(NSString *)streamID {
    ZGLogInfo(@"拉流分辨率更新回调: %dx%d", (int)size.height, (int)size.width);
    if ([self.delegate respondsToSelector:@selector(onSVCVideoSizeChanged:)]) {
        NSString *resolutionString = [NSString stringWithFormat:@"拉流分辨率更新为: %dx%d", (int)size.height, (int)size.width];
        [self.delegate onSVCVideoSizeChanged:resolutionString];
    }
}

@end

#endif
