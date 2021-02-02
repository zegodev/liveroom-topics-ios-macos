//
//  ZGAppGlobalConfigManager.h
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/8/6.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZGAppGlobalConfig.h"

NS_ASSUME_NONNULL_BEGIN

@class ZGAppGlobalConfigManager;

/**
 App 全局设置更新事件处理协议
 */
@protocol ZGAppGlobalConfigChangedHandler <NSObject>

- (void)configManager:(ZGAppGlobalConfigManager *)configManager appGlobalConfigChanged:(ZGAppGlobalConfig *)configInfo;

@end

/**
 App 全局设置管理器。
 
 * 通过实现 `ZGAppGlobalConfigChangedHandler` 并添加到管理器中，可以收到 App 全局设置更新事件。
 */
@interface ZGAppGlobalConfigManager : NSObject

+ (instancetype)sharedInstance;


/**
 默认全局配置

 @return 返回默认全局配置
 */
+ (ZGAppGlobalConfig *)defaultGlobalConfig;

/**
 更新全局配置
 
 @param config 新配置
 */
- (void)setGlobalConfig:(ZGAppGlobalConfig *)config;

/**
 获取保存的全局配置。如果不存在保存的设置或获取失败时，则返回默认值。
 */
- (ZGAppGlobalConfig *)globalConfig;

/**
 添加全局设置更新事件处理器。弱引用实现
 
 @param handler handler
 */
- (void)addGlobalConfigChangedHandler:(id<ZGAppGlobalConfigChangedHandler>)handler;

/**
 移除全局设置更新事件处理器
 
 @param handler handler
 */
- (void)removeGlobalConfigChangedHandler:(id<ZGAppGlobalConfigChangedHandler>)handler;

@end

NS_ASSUME_NONNULL_END
