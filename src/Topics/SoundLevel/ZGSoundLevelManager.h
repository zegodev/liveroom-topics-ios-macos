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

@protocol ZGSoundLevelDataSource <NSObject>

// 房间内流数量变化回调通知
- (void)onRemoteStreamsUpdate;

// 本地推流音频频谱数据变化回调通知
- (void)onCaptureFrequencySpectrumDataUpdate:(NSArray<NSNumber *> *)captureSpectrumList;
// 拉流音频频谱数据变化回调通知
- (void)onRemoteFrequencySpectrumDataUpdate:(NSDictionary<NSString *, NSArray <NSNumber *> *> *)remoteSpectrumDict;

// 本地推流声浪数据变化回调通知
- (void)onCaptureSoundLevelDataUpdate:(NSNumber *)captureSoundLevel;
// 拉流声浪数据变化回调通知
- (void)onRemoteSoundLevelDataUpdate:(NSDictionary<NSString *, NSNumber *> *)remoteSoundLevelDict;

@end

@interface ZGSoundLevelManager : NSObject

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

- (instancetype)initWithRoomID:(NSString *)roomID;

- (void)setZGSoundLevelDataSource:(id<ZGSoundLevelDataSource>)dataSource;

@end

NS_ASSUME_NONNULL_END

#endif
