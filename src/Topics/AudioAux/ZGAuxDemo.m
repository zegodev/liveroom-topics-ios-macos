//
//  ZGAuxDemo.m
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/8/16.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_AudioAux

#import "ZGAuxDemo.h"
#import "ZGAppGlobalConfigManager.h"
#import "ZGAppSignHelper.h"
#import "ZGUserIDHelper.h"
#if TARGET_OS_OSX
#import <ZegoLiveRoomOSX/ZegoLiveRoomApi.h>
#elif TARGET_OS_IOS
#import <ZegoLiveRoom/ZegoLiveRoom.h>
#import <ZegoLiveRoom/zego-api-audio-aux-oc.h>
#endif

@interface ZGAuxDemo () <ZegoLivePublisherDelegate, ZegoLivePlayerDelegate, ZegoAudioAuxDelgate>

@property (nonatomic, strong) ZegoLiveRoomApi *zegoApi;
@property (nonatomic, strong) ZegoAudioAux *audioAux;

//混音时的数据源
@property (nonatomic, strong) NSData *auxData;
@property (nonatomic, assign) void *pPos;

@property (nonatomic, copy) NSString *roomID;
@property (nonatomic, copy) NSString *streamID;
@property (nonatomic, assign) BOOL isAnchor;

@end

@implementation ZGAuxDemo

- (instancetype)initWithRoomID:(NSString *)roomID streamID:(NSString *)streamID isAnchor:(BOOL)isAnchor {
    self = [super init];
    if (self) {
        self.roomID = roomID;
        self.streamID = streamID;
        self.isAnchor = isAnchor;
        
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
        
        self.audioAux = [[ZegoAudioAux alloc] init];
        [self.audioAux setDelegate:self];
    }
    return self;
}

- (void)dealloc {
    [self.zegoApi logoutRoom];
    ZGLogInfo(@"退出房间");
    self.audioAux = nil;
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
        [self.zegoApi setPreviewViewMode:ZegoVideoViewModeScaleAspectFill];
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

- (void)onSwitchAux:(BOOL)enable {
    BOOL result = [self.audioAux enableAux:enable];
    if (result) {
        ZGLogInfo(@"☀️%@混音成功", enable ? @"开启" : @"关闭");
    } else {
        ZGLogError(@"⛈%@混音失败", enable ? @"开启" : @"关闭");
    }
}

- (void)changeAuxVolume:(int)volume {
    [self.audioAux setAuxVolume:volume];
}

- (void)onSwitchMuteAux:(BOOL)enable {
    BOOL result = [self.audioAux muteAux:enable];
    if (result) {
        ZGLogInfo(@"☀️%@静音成功", enable ? @"打开" : @"关闭");
    } else {
        ZGLogError(@"⛈%@静音失败", enable ? @"打开" : @"关闭");
    }
}

#pragma mark - Publisher Delegate

- (void)onPublishStateUpdate:(int)stateCode streamID:(NSString *)streamID streamInfo:(NSDictionary *)info {
    ZGLogInfo(@"推流状态回调:%d, streamID:%@", stateCode, streamID);
    if ([self.delegate respondsToSelector:@selector(onAuxPublishStateUpdate:)]) {
        NSString *stateString = stateCode == 0 ? @"🔵推流中" : [NSString stringWithFormat:@"❗️Error:%d", stateCode];
        [self.delegate onAuxPublishStateUpdate:stateString];
    }
}


- (void)onPublishQualityUpdate:(NSString *)streamID quality:(ZegoApiPublishQuality)quality {
    //    ZGLogInfo(@"推流质量更新：分辨率：%dx%d, 帧率：%ffps, 码率：%fkbps", quality.height, quality.width, quality.fps, quality.kbps);
    if ([self.delegate respondsToSelector:@selector(onAuxPublishQualityUpdate:)]) {
        NSString *qualityString = [NSString stringWithFormat:@"分辨率：%dx%d \n帧率：%.2f fps \n码率：%.2f kbps", quality.height, quality.width, quality.fps, quality.kbps];
        [self.delegate onAuxPublishQualityUpdate:qualityString];
    }
}

#pragma mark - Player Delegate

- (void)onPlayStateUpdate:(int)stateCode streamID:(NSString *)streamID {
    ZGLogInfo(@"拉流状态回调:%d, streamID:%@", stateCode, streamID);
    if ([self.delegate respondsToSelector:@selector(onAuxPlayStateUpdate:)]) {
        NSString *stateString = stateCode == 0 ? @"🔵拉流中" : [NSString stringWithFormat:@"❗️Error:%d", stateCode];
        [self.delegate onAuxPlayStateUpdate:stateString];
    }
}


- (void)onPlayQualityUpate:(NSString *)streamID quality:(ZegoApiPlayQuality)quality {
    //    ZGLogInfo(@"拉流质量更新:分辨率:%dx%d, 帧率:%ffps, 码率:%fkbps", quality.height, quality.width, quality.fps, quality.kbps);
    if ([self.delegate respondsToSelector:@selector(onAuxPlayQualityUpdate:)]) {
        NSString *qualityString = [NSString stringWithFormat:@"分辨率：%dx%d \n帧率：%.2f fps \n码率：%.2f kbps", quality.height, quality.width, quality.fps, quality.kbps];
        [self.delegate onAuxPlayQualityUpdate:qualityString];
    }
}


#pragma mark - ZegoAudioAux Delgate

- (void)onAuxCallback:(void *)pData dataLen:(int *)pDataLen sampleRate:(int *)pSampleRate channelCount:(int *)pChannelCount {
    if (self.auxData == nil) {
        //初始化auxData
        NSURL *auxURL = [[NSBundle mainBundle] URLForResource:@"sample.wav" withExtension:nil];
        if (auxURL) {
            self.auxData = [NSData dataWithContentsOfURL:auxURL options:0 error:nil];
            self.pPos = (void *)[self.auxData bytes];
        }
    }
    
    if (self.auxData) {
        int nLen = (int)[self.auxData length];
        if (self.pPos == 0)
            self.pPos = (void *)[self.auxData bytes];
        
        const void *pAuxData = [self.auxData bytes];
        if (pAuxData == NULL)
            return;
        
        *pSampleRate = 16000;
        *pChannelCount = 1;
        
        int nLeftLen = (int)(pAuxData + nLen - self.pPos);
        if (nLeftLen < *pDataLen) {
            self.pPos = (void *)pAuxData;
            *pDataLen = 0;
            return;
        }
        memcpy(pData, self.pPos, *pDataLen);
        self.pPos = self.pPos + *pDataLen;
    }
}


@end

#endif
