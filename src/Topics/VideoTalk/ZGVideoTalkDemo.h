//
//  ZGVideoTalkDemo.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/3.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_VideoTalk

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


/**
 视频通话加入房间状态

 - ZGVideoTalkJoinRoomStateNotJoin: 还未加入
 - ZGVideoTalkJoinRoomStateOnRequestJoin: 请求加入中
 - ZGVideoTalkJoinRoomStateJoined: 已加入
 */
typedef NS_ENUM(NSUInteger, ZGVideoTalkJoinRoomState) {
    ZGVideoTalkJoinRoomStateNotJoin,
    ZGVideoTalkJoinRoomStateOnRequestJoin,
    ZGVideoTalkJoinRoomStateJoined
};

@class ZGVideoTalkDemo;

@protocol ZGVideoTalkDemoDataSource <NSObject>

@required

/**
 获取本地用户加入视频通话的推流 ID

 @param demo ZGVideoTalkDemo 实例
 @return 推流 ID
 */
- (NSString *)localUserJoinTalkStreamID:(ZGVideoTalkDemo *)demo;
/**
 获取本地用户视频通话的预览视图

 @param demo ZGVideoTalkDemo 实例
 @return 预览视图
 */
- (UIView *)localUserPreviewView:(ZGVideoTalkDemo *)demo;

/**
 获取远端用户的视频通话播放视图

 @param demo ZGVideoTalkDemo 实例
 @param userID 远端用户 UserID
 @return 播放视图
 */
- (UIView *)videoTalkDemo:(ZGVideoTalkDemo *)demo playViewForRemoteUserWithID:(NSString *)userID;

@end

@protocol ZGVideoTalkDemoDelegate <NSObject>

/**
 本地用户被踢出房间事件。若有相同 userID 用户登录同一房间，则先登录的用户会被踢出。
 
 @param demo ZGVideoTalkDemo 实例
 @param roomID 通话房间 ID
 */
- (void)videoTalkDemo:(ZGVideoTalkDemo *)demo kickOutTalkRoom:(NSString *)roomID;

/**
 断开房间连接事件。

 @param demo ZGVideoTalkDemo 实例
 @param roomID 通话房间 ID
 */
- (void)videoTalkDemo:(ZGVideoTalkDemo *)demo disConnectTalkRoom:(NSString *)roomID;

/**
 本地用户加入房间状态变化事件。
 
 @param demo ZGVideoTalkDemo 实例
 @param state 加入房间的状态
 @param roomID 通话房间 ID
 */
- (void)videoTalkDemo:(ZGVideoTalkDemo *)demo
localUserJoinRoomStateUpdated:(ZGVideoTalkJoinRoomState)state
               roomID:(NSString *)roomID;

/**
 远端用户加入通话事件。
 
 @param demo ZGVideoTalkDemo 实例
 @param talkRoomID 通话房间 ID
 @param userIDs 用户 id 列表
 */
- (void)videoTalkDemo:(ZGVideoTalkDemo *)demo
remoteUserDidJoinTalkInRoom:(NSString *)talkRoomID
              userIDs:(NSArray<NSString *> *)userIDs;

/**
 远端用户离开通话事件。

 @param demo ZGVideoTalkDemo 实例
 @param talkRoomID 通话房间 ID
 @param userIDs 用户 id 列表
 */
- (void)videoTalkDemo:(ZGVideoTalkDemo *)demo
remoteUserDidLeaveTalkInRoom:(NSString *)talkRoomID
              userIDs:(NSArray<NSString *> *)userIDs;


/**
 远端视频通话用户视频状态变化事件。

 @param demo ZGVideoTalkDemo 实例
 @param stateCode 状态码。stateCode != 0 表示发生错误。发生错误后，用户可实现自己的逻辑。
 @param userID 用户 ID
 */
- (void)videoTalkDemo:(ZGVideoTalkDemo *)demo
remoteUserVideoStateUpdate:(int)stateCode
           userID:(NSString *)userID;

@end

/**
 视频通话 VM 类。瘦身 ViewController，抽象视频通话的逻辑并封装为接口和属性，简化整个交互流程。
 
 它的基本使用流程为：
 1.使用 initWithAppID 初始化，初始化成功后，后续的其他方法才能有效使用。
 2.使用 joinTalkRoom 加入通话房间，使用 leaveTalkRoom 退出通话
 3.通过代理的 didJoinTalkRoom, didLeaveTalkRoom 方法获取远端用户的加入和离开通知，在界面上做相应 UI 的处理，如增加和删除视频通话视图的数据源。
 
 @discussion 简化SDK视频通话一系列接口，用户可以参考该类实现构建自己的业务。
 @note 开发者可参考该类的代码, 理解视频通话涉及的 SDK 接口
 */

@interface ZGVideoTalkDemo : NSObject

// 是否启用相机
@property (nonatomic, readonly) BOOL enableCamera;

// 是否启用麦克风
@property (nonatomic, readonly) BOOL enableMic;

// 房间登录状态
@property (nonatomic, readonly) ZGVideoTalkJoinRoomState joinRoomState;

// 登录的房间 id
@property (nonatomic, readonly) NSString *talkRoomID;

// 本地用户通话的推流 ID
@property (nonatomic, readonly) NSString *localStreamID;

// 当前本地用户 ID
@property (nonatomic, readonly) NSString *localUserID;

// 参与通话的远程用户 ID 列表
@property (nonatomic, readonly) NSArray<NSString *> *remoteUserIDList;

// dataSource
@property (nonatomic, weak) id<ZGVideoTalkDemoDataSource> dataSource;
// 代理
@property (nonatomic, weak) id<ZGVideoTalkDemoDelegate> delegate;

- (instancetype)init NS_UNAVAILABLE;

/**
 初始化 ZGVideoTalkDemo 实例。

 @param appID appID
 @param appSign appSign
 @param completionBlock 初始化回调。errorCode == 0 表示成功。
 @return 是否初始化成功
 */
- (instancetype)initWithAppID:(unsigned int)appID
                      appSign:(NSData *)appSign
              completionBlock:(void(^)(ZGVideoTalkDemo *demo, int errorCode))completionBlock;

/**
 启用或停用麦克风。初始化回调的 errorCode == 0 时设置才有效。
 
 @param enableMic 是否开启
 */
- (void)setEnableMic:(BOOL)enableMic;

/**
 启用或停用摄像头。初始化回调的 errorCode == 0 时设置才有效。
 
 @param enableCamera 是否开启
 */
- (void)setEnableCamera:(BOOL)enableCamera;

/**
 加入视频聊天。初始化回调的 errorCode == 0 时设置才有效。

 @param talkRoomID 通话房间 ID。根据业务取系统唯一值
 @param userID 用户 ID。根据业务取系统惟一值，最好有意义
 @param callback 回调。errorCode 为 0 表示加入成功，joinTalkUserIDs：房间内已加入到通话的用户 ID 列表
 @return 请求是否发送成功
 */
- (BOOL)joinTalkRoom:(NSString *)talkRoomID
              userID:(NSString *)userID
            callback:(void(^)(int errorCode, NSArray<NSString *> *joinTalkUserIDs))callback;

/**
 离开视频聊天房间。初始化回调的 errorCode == 0 时设置才有效。
 
 @return 是否成功
 */
- (BOOL)leaveTalkRoom;

@end


NS_ASSUME_NONNULL_END

#endif
