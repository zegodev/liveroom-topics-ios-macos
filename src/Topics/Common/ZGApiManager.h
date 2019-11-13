//
//  ZGApiManager.h
//  LiveRoomPlayground
//
//  Copyright © 2018年 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZGAppGlobalConfigManager.h"

#if TARGET_OS_OSX
#import <ZegoLiveRoomOSX/ZegoLiveRoomApi.h>
#import <ZegoLiveRoomOSX/ZegoLiveRoomApi-Player.h>
#import <ZegoLiveRoomOSX/ZegoLiveRoomApi-Publisher.h>
#elif TARGET_OS_IOS
#import <ZegoLiveRoom/ZegoLiveRoomApi.h>
#import <ZegoLiveRoom/ZegoLiveRoomApi-Player.h>
#import <ZegoLiveRoom/ZegoLiveRoomApi-Publisher.h>
#endif


NS_ASSUME_NONNULL_BEGIN

/**
 Api初始化管理类
 */
@interface ZGApiManager : NSObject


/**
 获取 ZegoLiveRoomApi 单例。如果该单例不存在，则会使用 ZGAppGlobalConfigManager 的默认配置初始化。
 */
@property (class, strong, nonatomic, readonly) ZegoLiveRoomApi *api;

+ (void)releaseApi;

/**
 初始化 ZegoLiveRoomApi 单例。该方法会重置 ZegoLiveRoomApi 单例。

 @param appID 给定的 appID
 @param appSign 给定的 appSign
 @param blk 回调
 @return 是否初始化成功
 */
+ (BOOL)initApiWithAppID:(unsigned int)appID appSign:(NSData *)appSign completionBlock:(nullable ZegoInitSDKCompletionBlock)blk;

@end

NS_ASSUME_NONNULL_END

