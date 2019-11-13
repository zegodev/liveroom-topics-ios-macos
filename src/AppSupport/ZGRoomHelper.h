//
//  ZGRoomHelper.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/19.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZGRoomInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZGRoomHelper : NSObject

/**
 查询房间列表。这是 ZEGO 的内部获取房间列表的一种临时方式，业务不可以依赖这种方式（不稳定），需要自己维护房间列表。

 @param appID 在 ZEGO 申请的 app id
 @param isTestEnv 是否为测试环境
 @param completion 回调
 */
+ (void)queryRoomListWithAppID:(unsigned int)appID
                     isTestEnv:(BOOL)isTestEnv
                    completion:(void(^)(NSArray<ZGRoomInfo*> *roomList, NSError *error))completion;

@end

NS_ASSUME_NONNULL_END
