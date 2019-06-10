//
//  ZGLoginRoomDemo.h
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/4/18.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 登录示例类
 
 @discussion 此类将SDK 初始化与房间登录等基本接口进行封装
 @note 开发者可参考该类的代码, 理解 SDK 接口
 */
@interface ZGLoginRoomDemo : NSObject

@property (assign, nonatomic, readonly) BOOL isLoginRoom;
@property (copy, nonatomic, readonly, nullable) NSString *roomID;
@property (strong, nonatomic, readonly) NSMutableSet<NSString*>* streamIDList;

+ (instancetype)shared;

- (BOOL)loginRoom:(NSString *)roomID role:(ZegoRole)role completion:(ZegoLoginCompletionBlock)completion;
- (void)logoutRoom;

@end

NS_ASSUME_NONNULL_END
