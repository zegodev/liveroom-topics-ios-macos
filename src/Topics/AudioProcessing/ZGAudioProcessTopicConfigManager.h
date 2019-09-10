//
//  ZGAudioProcessTopicConfigManager.h
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/8/27.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_AudioProcessing

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ZGAudioProcessTopicConfigManager;
@protocol ZGAudioProcessTopicConfigChangedHandler <NSObject>
@optional
- (void)audioProcessTopicConfigManager:(ZGAudioProcessTopicConfigManager *)configManager
               voiceChangerOpenChanged:(BOOL)voiceChangerOpen;

- (void)audioProcessTopicConfigManager:(ZGAudioProcessTopicConfigManager *)configManager
               voiceChangerParamChanged:(float)voiceChangerParam;

- (void)audioProcessTopicConfigManager:(ZGAudioProcessTopicConfigManager *)configManager
              virtualStereoOpenChanged:(BOOL)virtualStereoOpen;

- (void)audioProcessTopicConfigManager:(ZGAudioProcessTopicConfigManager *)configManager
              virtualStereoAngleChanged:(int)virtualStereoAngle;

- (void)audioProcessTopicConfigManager:(ZGAudioProcessTopicConfigManager *)configManager
             reverbOpenChanged:(BOOL)reverbOpen;

- (void)audioProcessTopicConfigManager:(ZGAudioProcessTopicConfigManager *)configManager
             reverbModeChanged:(NSUInteger)reverbMode;

- (void)audioProcessTopicConfigManager:(ZGAudioProcessTopicConfigManager *)configManager
             customReverbRoomSizeChanged:(float)customReverbRoomSize;

- (void)audioProcessTopicConfigManager:(ZGAudioProcessTopicConfigManager *)configManager
           customDryWetRatioChanged:(float)customDryWetRatio;

- (void)audioProcessTopicConfigManager:(ZGAudioProcessTopicConfigManager *)configManager
              customDampingChanged:(float)customDamping;

- (void)audioProcessTopicConfigManager:(ZGAudioProcessTopicConfigManager *)configManager
                  customReverberanceChanged:(float)customReverberance;

@end

/**
 音频处理专题设置管理器。
 
 * 通过实现 `ZGAudioProcessTopicConfigChangedHandler` 并添加到管理器中，可以收到专题设置更新事件。
 */
@interface ZGAudioProcessTopicConfigManager : NSObject

+ (instancetype)sharedInstance;

- (void)addConfigChangedHandler:(id<ZGAudioProcessTopicConfigChangedHandler>)handler;

- (void)removeConfigChangedHandler:(id<ZGAudioProcessTopicConfigChangedHandler>)handler;

#pragma mark - 变声

/**
 保存`是否开启变声`设置
 */
- (void)setVoiceChangerOpen:(BOOL)voiceChangerOpen;

/**
 返回保存的`是否开启变声`。如果不存在，则返回默认
 */
- (BOOL)voiceChangerOpen;

/**
 保存`变声系数`设置
 */
- (void)setVoiceChangerParam:(float)voiceChangerParam;

/**
 返回保存的`变声系数`。如果不存在，则返回默认
 */
- (float)voiceChangerParam;

#pragma mark - 立体声

/**
 保存`是否开启立体声`设置
 */
- (void)setVirtualStereoOpen:(BOOL)virtualStereoOpen;

/**
 返回保存的`是否开启立体声`。如果不存在，则返回默认
 */
- (BOOL)virtualStereoOpen;

/**
 保存`立体声位置角度`设置
 */
- (void)setVirtualStereoAngle:(int)angle;

/**
 返回保存的`立体声位置角度`。如果不存在，则返回默认
 */
- (int)virtualStereoAngle;


#pragma mark - 混响
/**
 保存`是否开启混响`设置
 */
- (void)setReverbOpen:(BOOL)reverbOpen;

/**
 返回保存的`是否开启混响`。如果不存在，则返回默认
 */
- (BOOL)reverbOpen;

/**
 保存`混响模式`设置
 */
- (void)setReverbMode:(NSUInteger)reverbMode;

/**
 返回保存的`混响模式`。如果不存在，则返回 NSNotfound
 */
- (NSUInteger)reverbMode;

/**
 保存`自定义混响的 roomSize`设置
 */
- (void)setCustomReverbRoomSize:(float)roomSize;

/**
 返回保存的`自定义混响的 roomSize`。如果不存在，则返回默认
 */
- (float)customReverbRoomSize;

/**
 保存`自定义混响的 dryWetRatio`设置
 */
- (void)setCustomDryWetRatio:(float)dryWetRatio;

/**
 返回保存的`自定义混响的 dryWetRatio`。如果不存在，则返回默认
 */
- (float)customDryWetRatio;

/**
 保存`自定义混响的 damping`设置
 */
- (void)setCustomDamping:(float)damping;

/**
 返回保存的`自定义混响的 damping`。如果不存在，则返回默认
 */
- (float)customDamping;

/**
 保存`自定义混响的 reverberance（余响）`设置
 */
- (void)setCustomReverberance:(float)reverberance;

/**
 返回保存的`自定义混响的 reverberance（余响）`。如果不存在，则返回默认
 */
- (float)customReverberance;

@end

NS_ASSUME_NONNULL_END
#endif
