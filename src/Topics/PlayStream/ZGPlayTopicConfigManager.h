//
//  ZGPlayTopicConfigManager.h
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/8/12.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ZGPlayTopicConfigManager;
/**
 拉流专题设置变化 handler 协议
 */
@protocol ZGPlayTopicConfigChangedHandler <NSObject>
@optional

- (void)playTopicConfigManager:(ZGPlayTopicConfigManager *)configManager playViewModeDidChange:(ZegoVideoViewMode)playViewMode;

- (void)playTopicConfigManager:(ZGPlayTopicConfigManager *)configManager playStreamVolumeDidChange:(int)playStreamVolume;

- (void)playTopicConfigManager:(ZGPlayTopicConfigManager *)configManager enableHardwareDecodeDidChange:(BOOL)enableHardwareDecode;

@end

/**
 拉流专题的拉流设置管理器。
 
 * 通过实现 `ZGPlayTopicConfigChangedHandler` 并添加到管理器中，可以收到拉流专题的拉流设置更新事件。
 */
@interface ZGPlayTopicConfigManager : NSObject

+ (instancetype)sharedInstance;

/**
 添加设置修改 handler 代理。弱引用实现
 */
- (void)addConfigChangedHandler:(id<ZGPlayTopicConfigChangedHandler>)handler;

/**
 删除设置修改 handler 代理
 */
- (void)removeConfigChangedHandler:(id<ZGPlayTopicConfigChangedHandler>)handler;


- (void)setPlayViewMode:(ZegoVideoViewMode)playViewMode;
/**
 返回拉流播放视图模式。如果不存在保存的设置，则返回默认值。
 */
- (ZegoVideoViewMode)playViewMode;

- (void)setPlayStreamVolume:(int)playStreamVolume;
/**
 返回是否拉流播放音量。如果不存在保存的设置，则返回默认值。
 */
- (int)playStreamVolume;

- (void)setEnableHardwareDecode:(BOOL)enableHardwareDecode;
/**
 返回是否启用硬件解码标识。如果不存在保存的设置，则返回默认值。
 */
- (BOOL)isEnableHardwareDecode;

@end

NS_ASSUME_NONNULL_END
