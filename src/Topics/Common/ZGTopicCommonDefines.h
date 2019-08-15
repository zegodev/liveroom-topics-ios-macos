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

#endif /* ZGTopicCommonDefines_h */
