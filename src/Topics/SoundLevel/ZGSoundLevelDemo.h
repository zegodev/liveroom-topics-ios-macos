//
//  SoundLevelDemo.h
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/8/26.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_SoundLevel

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ZGSoundLevelDemoProtocol <NSObject>

// 房间内流数量变化回调通知
- (void)onRemoteStreamsUpdate;

// 本地推流音频频谱数据变化回调通知
- (void)onCaptureFrequencySpectrumDataUpdate;
// 拉流音频频谱数据变化回调通知
- (void)onRemoteFrequencySpectrumDataUpdate;

// 本地推流声浪数据变化回调通知
- (void)onCaptureSoundLevelDataUpdate;
// 拉流声浪数据变化回调通知
- (void)onRemoteSoundLevelDataUpdate;

@end

@interface ZGSoundLevelDemo : NSObject

// 是否开启音频频谱监控
@property (nonatomic, assign) BOOL enableFrequencySpectrumMonitor;
// 是否开启声浪监控
@property (nonatomic, assign) BOOL enableSoundLevelMonitor;
// 音频频谱监控周期
@property (nonatomic, assign) unsigned int frequencySpectrumMonitorCycle;
// 声浪监控周期
@property (nonatomic, assign) unsigned int soundLevelMonitorCycle;

// 本地推流 ID
@property (nonatomic, copy, readonly) NSString *localStreamID;
// 房间内其他流 ID 列表
@property (nonatomic, strong, readonly) NSMutableArray<NSString *> *remoteStreamIDList;

// 本地推流音频频谱数据
@property (nonatomic, copy) NSArray<NSNumber *> *captureSpectrumList;
// 房间内其他流音频频谱数据
@property (nonatomic, strong) NSMutableArray<NSArray <NSNumber *> *> *remoteSpectrumList;

// 本地推流声浪数据
@property (nonatomic, strong) NSNumber *captureSoundLevel;
// 房间内其他流声浪数据
@property (nonatomic, strong) NSMutableArray<NSNumber *> *remoteSoundLevelList;

- (instancetype)initWithRoomID:(NSString *)roomID;

- (void)setZGSoundLevelDelegate:(id<ZGSoundLevelDemoProtocol>)delegate;

@end

NS_ASSUME_NONNULL_END

#endif
