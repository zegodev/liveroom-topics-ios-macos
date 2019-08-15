//
//  ZGPublishTopicConfigManager.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/7.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ZGPublishTopicConfigManager;
/**
 推流专题设置变化 handler 协议
 */
@protocol ZGPublishTopicConfigChangedHandler <NSObject>
@optional

- (void)publishTopicConfigManager:(ZGPublishTopicConfigManager *)configManager resolutionDidChange:(CGSize)resolution;

- (void)publishTopicConfigManager:(ZGPublishTopicConfigManager *)configManager fpsDidChange:(NSInteger)fps;

- (void)publishTopicConfigManager:(ZGPublishTopicConfigManager *)configManager bitrateDidChange:(NSInteger)bitrate;

- (void)publishTopicConfigManager:(ZGPublishTopicConfigManager *)configManager previewViewModeDidChange:(ZegoVideoViewMode)previewViewMode;

- (void)publishTopicConfigManager:(ZGPublishTopicConfigManager *)configManager enableHardwareEncodeDidChange:(BOOL)enableHardwareEncode;

- (void)publishTopicConfigManager:(ZGPublishTopicConfigManager *)configManager previewMinnorDidChange:(BOOL)isPreviewMinnor;

@end

/**
 推流专题的推流设置管理器。
 
 * 通过实现 `ZGPublishTopicConfigChangedHandler` 并添加到管理器中，可以收到推流专题的推流设置更新事件。
 */
@interface ZGPublishTopicConfigManager : NSObject

+ (instancetype)sharedInstance;

/**
 添加设置修改 handler 代理。弱引用实现
 */
- (void)addConfigChangedHandler:(id<ZGPublishTopicConfigChangedHandler>)handler;

/**
 删除设置修改 handler 代理
 */
- (void)removeConfigChangedHandler:(id<ZGPublishTopicConfigChangedHandler>)handler;


- (void)setResolution:(CGSize)resolution;
/**
 返回分辨率。如果不存在保存的设置，则返回默认值。
 */
- (CGSize)resolution;

- (void)setFps:(NSInteger)fps;
/**
 返回帧率。如果不存在保存的设置，则返回默认值。
 */
- (NSInteger)fps;

- (void)setBitrate:(NSInteger)bitrate;
/**
 返回码率。如果不存在保存的设置，则返回默认值。
 */
- (NSInteger)bitrate;

- (void)setPreviewViewMode:(ZegoVideoViewMode)previewViewMode;
/**
 返回预览视图模式。如果不存在保存的设置，则返回默认值。
 */
- (ZegoVideoViewMode)previewViewMode;

- (void)setEnableHardwareEncode:(BOOL)enableHardwareEncode;
/**
 返回是否启用硬件编码标识。如果不存在保存的设置，则返回默认值。
 */
- (BOOL)isEnableHardwareEncode;

- (void)setPreviewMinnor:(BOOL)isPreviewMinnor;
/**
 返回是否启用预览镜像标识。如果不存在保存的设置，则返回默认值。
 */
- (BOOL)isPreviewMinnor;

@end

NS_ASSUME_NONNULL_END
