//
//  ZGCustomTokenHelper.h
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/8/19.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZGCustomTokenHelper : NSObject

/**
 生成 CustomToken 供房间登录鉴权
 
 * 1. 在执行 LoginRoom 之前，向业务服务器申请一个 third_token，通过SDK API接口 SetCustomToken 设置到 SDK；
 * 2. ZEGO后台在验证登录合法性时，当 third_token 验证不通过，客户端 OnLogin 回调返回错误码：1050578；

 @param appID zego 提供的 appID。需要联系 ZEGO 技术支持获得。
 @param timeout 超时时间
 @param idName 和 userID 一致的值
 @param serverSecret ServerSecret 需要联系 ZEGO 技术支持获得。
 @return 生成 custom token
 */
+ (NSString *)generateThirdTokenWithAppID:(unsigned int)appID timeout:(long)timeout idName:(NSString *)idName serverSecret:(NSString *)serverSecret;

@end

NS_ASSUME_NONNULL_END
