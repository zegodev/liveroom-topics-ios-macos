//
//  SoundLevelDemo.m
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/8/26.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_SoundLevel

#import "ZGSoundLevelDemo.h"
#import "ZGAppGlobalConfigManager.h"
#import "ZGAppSignHelper.h"
#import "ZGUserIDHelper.h"
#import <math.h>
#import <sys/utsname.h>
#if TARGET_OS_OSX
#import <ZegoLiveRoomOSX/ZegoLiveRoomApi.h>
#import <ZegoLiveRoomOSX/zego-api-sound-level-oc.h>
#import <ZegoLiveRoomOSX/zego-api-frequency-spectrum-oc.h>
#elif TARGET_OS_IOS
#import <ZegoLiveRoom/ZegoLiveRoom.h>
#import <ZegoLiveRoom/zego-api-sound-level-oc.h>
#import <ZegoLiveRoom/zego-api-frequency-spectrum-oc.h>
#endif

@interface ZGSoundLevelDemo () <ZegoRoomDelegate, ZegoLivePublisherDelegate, ZegoLivePlayerDelegate, ZegoFrequencySpectrumDelegate, ZegoSoundLevelDelegate>

@property (nonatomic, strong) ZegoLiveRoomApi *zegoApi;
@property (nonatomic, weak) id <ZGSoundLevelDemoProtocol>delegate;
@property (nonatomic, copy) NSString *roomID;
@property (nonatomic, copy, readwrite) NSString *localStreamID;
@property (nonatomic, strong, readwrite) NSMutableArray<NSString *> *remoteStreamIDList;

@end

@implementation ZGSoundLevelDemo

- (void)dealloc {
    [self.zegoApi stopPublishing];
    [self.zegoApi logoutRoom];
    self.zegoApi = nil;
    
    [[ZegoFrequencySpectrum sharedInstance] setFrequencySpectrumDelegate:nil];
    [[ZegoSoundLevel sharedInstance] setSoundLevelDelegate:nil];
}

- (instancetype)initWithRoomID:(NSString *)roomID {
    self = [super init];
    if (self) {
        // 设置声浪和音频频谱回调代理
        [[ZegoFrequencySpectrum sharedInstance] setFrequencySpectrumDelegate:self];
        [[ZegoSoundLevel sharedInstance] setSoundLevelDelegate:self];
        
        self.roomID = roomID;
        self.localStreamID = [NSString stringWithFormat:@"%@-%@", [self getCurrentDeviceModel], [ZGUserIDHelper.userID substringToIndex:4]];
        self.remoteStreamIDList = [NSMutableArray<NSString *> array];
        self.remoteSpectrumList = [NSMutableArray<NSArray <NSNumber *> *> array];
        self.remoteSoundLevelList = [NSMutableArray<NSNumber *> array];
        
        ZGAppGlobalConfig *appConfig = [[ZGAppGlobalConfigManager sharedInstance] globalConfig];
        [ZegoLiveRoomApi setUseTestEnv:(appConfig.environment == ZGAppEnvironmentTest)];
        
        self.zegoApi = [[ZegoLiveRoomApi alloc] initWithAppID:(unsigned int)appConfig.appID appSignature:[ZGAppSignHelper convertAppSignFromString:appConfig.appSign] completionBlock:^(int errorCode) {
            if (errorCode == 0) {
                NSLog(@"初始化 SDK 成功");
                ZegoAVConfig *avConfig = [ZegoAVConfig presetConfigOf:ZegoAVConfigPreset_Veryhigh];
                [self.zegoApi setAVConfig:avConfig];
                [self.zegoApi setRoomDelegate:self];
                [self.zegoApi setPublisherDelegate:self];
                [self.zegoApi setPlayerDelegate:self];
                
                [self startLive];
            } else {
                NSLog(@"初始化 SDK 失败，错误码: %d", errorCode);
            }
        }];
    }
    return self;
}

- (void)setZGSoundLevelDelegate:(id<ZGSoundLevelDemoProtocol>)delegate {
    self.delegate = delegate;
}

#pragma mark - Private Methods

- (void)startLive {
    [ZegoLiveRoomApi setUserID:self.localStreamID userName:self.localStreamID];
    
    [self.zegoApi loginRoom:self.roomID role:ZEGO_ANCHOR withCompletionBlock:^(int errorCode, NSArray<ZegoStream *> *streamList) {
        if (errorCode == 0) {
            NSLog(@"登录房间成功");
            
            for (ZegoStream *remoteStream in streamList) {
                NSString *remoteStreamID = remoteStream.streamID;
                [self addRemoteStream:remoteStreamID];
            }
            
            [self.zegoApi enableCamera:NO];
            [self.zegoApi startPublishing:self.localStreamID title:nil flag:ZEGOAPI_JOIN_PUBLISH];
        } else {
            NSLog(@"登录房间失败，错误码：%d", errorCode);
        }
    }];
}

// 房间内新增流
- (void)addRemoteStream:(NSString *)streamID {
    [self.remoteStreamIDList addObject:streamID];
    [self.zegoApi startPlayingStream:streamID inView:nil];
    // 通知 UI 更新流数据
    if ([self.delegate respondsToSelector:@selector(onRemoteStreamsUpdate)]) {
        [self.delegate onRemoteStreamsUpdate];
    }
}

// 房间内删除流
- (void)removeRemoteStream:(NSString *)streamID {
    [self.remoteStreamIDList removeObject:streamID];
    [self.zegoApi stopPlayingStream:streamID];
    // 通知 UI 更新流数据
    if ([self.delegate respondsToSelector:@selector(onRemoteStreamsUpdate)]) {
        [self.delegate onRemoteStreamsUpdate];
    }
}

// 获取设备内部型号
- (NSString *)getCurrentDeviceModel {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
}

#pragma mark - FrequencySpectrum Setting

- (void)setEnableFrequencySpectrumMonitor:(BOOL)enable {
    BOOL result = nil;
    if (enable) {
        result = [[ZegoFrequencySpectrum sharedInstance] startFrequencySpectrumMonitor];
    } else {
        result = [[ZegoFrequencySpectrum sharedInstance] stopFrequencySpectrumMonitor];
    }
    NSLog(@"%@音频频谱%@", enable ? @"开启" : @"关闭", result ? @"成功☀️" : @"失败⛈");
    _enableFrequencySpectrumMonitor = enable;
}

- (void)setFrequencySpectrumMonitorCycle:(unsigned int)timeInMS {
    [[ZegoFrequencySpectrum sharedInstance] stopFrequencySpectrumMonitor];
    [[ZegoFrequencySpectrum sharedInstance] setFrequencySpectrumMonitorCycle:timeInMS];
    [[ZegoFrequencySpectrum sharedInstance] startFrequencySpectrumMonitor];
    _frequencySpectrumMonitorCycle = timeInMS;
}

#pragma mark - SoundLevel Setting

- (void)setEnableSoundLevelMonitor:(BOOL)enable {
    BOOL result = nil;
    if (enable) {
        result = [[ZegoSoundLevel sharedInstance] startSoundLevelMonitor];
    } else {
        result = [[ZegoSoundLevel sharedInstance] stopSoundLevelMonitor];
    }
    NSLog(@"%@声浪%@", enable ? @"开启" : @"关闭", result ? @"成功☀️" : @"失败⛈");
    _enableSoundLevelMonitor = enable;
}

- (void)setSoundLevelMonitorCycle:(unsigned int)timeInMS {
    [[ZegoSoundLevel sharedInstance] stopSoundLevelMonitor];
    [[ZegoSoundLevel sharedInstance] setSoundLevelMonitorCycle:timeInMS];
    [[ZegoSoundLevel sharedInstance] startSoundLevelMonitor];
    _soundLevelMonitorCycle = timeInMS;
}


#pragma mark - ZegoFrequencySpectrumDelegate

- (void)onFrequencySpectrumUpdate:(NSArray<ZegoFrequencySpectrumInfo *> *)spectrumInfos {
    [self.remoteSpectrumList removeAllObjects];
    for (ZegoFrequencySpectrumInfo *info in spectrumInfos) {
        [self.remoteSpectrumList addObject:info.spectrumList];
    }
    
    // 通知 UI 更新音频频谱数据
    if ([self.delegate respondsToSelector:@selector(onRemoteFrequencySpectrumDataUpdate)]) {
        [self.delegate onRemoteFrequencySpectrumDataUpdate];
    }
}

- (void)onCaptureFrequencySpectrumUpdate:(ZegoFrequencySpectrumInfo *)captureSpectrum {
    self.captureSpectrumList = captureSpectrum.spectrumList;
    
    // 通知 UI 更新音频频谱数据
    if ([self.delegate respondsToSelector:@selector(onCaptureFrequencySpectrumDataUpdate)]) {
        [self.delegate onCaptureFrequencySpectrumDataUpdate];
    }
}

#pragma mark - ZegoSoundLevelDelegate

- (void)onSoundLevelUpdate:(NSArray<ZegoSoundLevelInfo *> *)soundLevels {
    [self.remoteSoundLevelList removeAllObjects];
    for (ZegoSoundLevelInfo *info in soundLevels) {
        [self.remoteSoundLevelList addObject:[NSNumber numberWithFloat:info.soundLevel]];
    }
    
    // 通知 UI 更新声浪数据
    if ([self.delegate respondsToSelector:@selector(onRemoteSoundLevelDataUpdate)]) {
        [self.delegate onRemoteSoundLevelDataUpdate];
    }
}


- (void)onCaptureSoundLevelUpdate:(ZegoSoundLevelInfo *)captureSoundLevel {
    self.captureSoundLevel = @(captureSoundLevel.soundLevel);
    
    // 通知 UI 更新声浪数据
    if ([self.delegate respondsToSelector:@selector(onCaptureSoundLevelDataUpdate)]) {
        [self.delegate onCaptureSoundLevelDataUpdate];
    }
}

#pragma mark - Room Delegate

- (void)onStreamUpdated:(int)type streams:(NSArray<ZegoStream *> *)streamList roomID:(NSString *)roomID {
    if (type == ZEGO_STREAM_ADD) {
        for (ZegoStream *remoteStream in streamList) {
            NSString *remoteStreamID = remoteStream.streamID;
            [self addRemoteStream:remoteStreamID];
        }
    } else {
        for (ZegoStream *remoteStream in streamList) {
            NSString *remoteStreamID = remoteStream.streamID;
            [self removeRemoteStream:remoteStreamID];
        }
    }
}

#pragma mark - Publish & Play Delegate

- (void)onPublishStateUpdate:(int)stateCode streamID:(NSString *)streamID streamInfo:(NSDictionary *)info {
    NSLog(@"推流状态: %d, streamID: %@", stateCode, streamID);
}

- (void)onPlayStateUpdate:(int)stateCode streamID:(NSString *)streamID{
    NSLog(@"拉流状态: %d, streamID: %@", stateCode, streamID);
}

@end

#endif
