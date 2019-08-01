//
//  ZGMixStreamTopicConfigManager.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/23.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZGMixStreamTopicConfig.h"

NS_ASSUME_NONNULL_BEGIN

@class ZGMixStreamTopicConfigManager;

/**
 混流配置更新的事件处理协议
 */
@protocol ZGMixStreamTopicConfigUpdatedHandler <NSObject>

- (void)configManager:(ZGMixStreamTopicConfigManager *)configManager mixStreamTopicConfigUpdated:(ZGMixStreamTopicConfig *)updatedConfig;

@end


/**
 混流配置管理器。通过实现 `ZGMixStreamTopicConfigUpdatedHandler` 并添加到管理器中，可以收到混流更新事件，根据需要进行处理
 */
@interface ZGMixStreamTopicConfigManager : NSObject

+ (instancetype)sharedInstance;

/**
 获取保存的配置

 @return 保存的配置
 */
- (ZGMixStreamTopicConfig *)loadConfig;

/**
 更新配置

 @param config 新配置
 */
- (void)updateConfig:(ZGMixStreamTopicConfig *)config;

/**
 添加配置更新事件处理器。弱引用实现

 @param handler handler
 */
- (void)addConfigUpdatedHandler:(id<ZGMixStreamTopicConfigUpdatedHandler>)handler;

/**
 移除配置更新事件处理器
 
 @param handler handler
 */
- (void)removeConfigUpdatedHandler:(id<ZGMixStreamTopicConfigUpdatedHandler>)handler;

@end

NS_ASSUME_NONNULL_END
