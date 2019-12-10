//
//  ZGTopicCommonDefines.h
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/8/7.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifndef ZGTopicCommonDefines_h
#define ZGTopicCommonDefines_h


/**
 房间登录状态
 */
typedef NS_ENUM(NSUInteger, ZGTopicLoginRoomState) {
    // 未登录
    ZGTopicLoginRoomStateNotLogin = 0,
    // 请求登录中
    ZGTopicLoginRoomStateLoginRequesting = 1,
    // 已登录
    ZGTopicLoginRoomStateLogined = 2
};

/**
 推流状态枚举
 */
typedef NS_ENUM(NSUInteger, ZGTopicPublishStreamState) {
    // 不在推流
    ZGTopicPublishStreamStateStopped = 0,
    // 请求推流中
    ZGTopicPublishStreamStatePublishRequesting = 1,
    // 正在推流
    ZGTopicPublishStreamStatePublishing = 2
};

// 保存全局配置的 key
#define ZGAPP_GLOBAL_CONFIG_KEY @"kZGAppGlobalConfig"

// 录屏进程的 zego SDK 日志目录
#define ZGAPP_REPLAYKIT_UPLOAD_EXTENSION_ZEGO_LOG_DIR @"replaykit_upload_extension_zegolog"

// app 共享数据组
#define ZGAPP_GROUP_NAME @"group.com.zego.doudong.LiveRoomPlayground"

// 宿主 app 的日志目录的完整地址(这里也是 zegoSDK log的默认地址)
#define ZG_HOST_APP_ZEGO_LOG_DIR_FULLPATH (\
    [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"ZegoLogs"] \
    )

#endif /* ZGTopicCommonDefines_h */
