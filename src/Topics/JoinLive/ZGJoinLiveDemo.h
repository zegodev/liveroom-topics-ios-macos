//
//  JoinLiveDemo.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/11.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_JoinLive

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 示例加入房间状态
 
 - ZGJoinLiveDemoJoinRoomStateNotJoin: 还未加入
 - ZGJoinLiveDemoJoinRoomStateOnRequestJoin: 请求加入中
 - ZGJoinLiveDemoJoinRoomStateHasJoin: 已加入
 */
typedef NS_ENUM(NSUInteger, ZGJoinLiveDemoJoinRoomState) {
    ZGJoinLiveDemoJoinRoomStateNotJoin,
    ZGJoinLiveDemoJoinRoomStateOnRequestJoin,
    ZGJoinLiveDemoJoinRoomStateHasJoin
};

@class ZGJoinLiveDemo;
@protocol JoinLiveDemoDataSource <NSObject>
@required

/**
 获取本地用户直播的推流 ID

 @param demo JoinLiveDemo 实例
 @return 推流 ID
 */
- (NSString *)localUserLiveStreamID:(ZGJoinLiveDemo *)demo;

/**
 获取本地用户直播视频预览的渲染视图

 @param demo JoinLiveDemo 实例
 @return 渲染视图
 */
- (UIView *)localUserLivePreviewView:(ZGJoinLiveDemo *)demo;

/**
 获取远端用户的直播播放的渲染视图

 @param demo JoinLiveDemo 实例
 @param remoteUserID 远端用户 ID
 @return 渲染视图
 */
- (UIView *)demo:(ZGJoinLiveDemo *)demo livePlayViewForRemoteUser:(NSString *)remoteUserID;

@end

@protocol JoinLiveDemoDelegate <NSObject>
@optional

/**
 本地用户被踢出房间事件。若有相同 userID 用户登录同一房间，则先登录的用户会被踢出。
 
 @param demo JoinLiveDemo 实例
 @param roomID 直播房间 ID
 */
- (void)demo:(ZGJoinLiveDemo *)demo kickOutRoom:(NSString *)roomID;

/**
 断开房间连接事件。
 
 @param demo JoinLiveDemo 实例
 @param roomID 直播房间 ID
 */
- (void)demo:(ZGJoinLiveDemo *)demo disConnectRoom:(NSString *)roomID;

/**
 本地用户直播状态变化事件。
 
 @param demo JoinLiveDemo 实例
 @param onLive 是否在直播（连麦）
 */
- (void)demo:(ZGJoinLiveDemo *)demo localUserOnLiveUpdated:(BOOL)onLive;

/**
 远端用户直播状态变化事件。
 
 @param demo JoinLiveDemo 实例
 @param onLive 是否在直播（连麦）
 @param remoteUserIDs 远端用户 ID 列表
 */
- (void)demo:(ZGJoinLiveDemo *)demo remoteUserOnLiveUpdated:(BOOL)onLive withUserIDs:(NSArray<NSString*> *)remoteUserIDs;

/**
 远端用户视频状态变化事件。
 
 @param demo ZGVideoTalkDemo 实例
 @param stateCode 状态码。stateCode != 0 表示发生错误。发生错误后，用户可实现自己的逻辑，如显示错误信息和暂停状态，然后显示播放按钮实现重新播放
 @param userID 用户 ID
 */
- (void)demo:(ZGJoinLiveDemo *)demo remoteUserLivePlayStateUpdate:(int)stateCode
           withUserID:(NSString *)userID;


/**
 远端用户加入房间事件。

 @param demo ZGVideoTalkDemo 实例
 @param userIDs 远端用户 ID 列表
 */
- (void)demo:(ZGJoinLiveDemo *)demo remoteUserJoinLiveRoom:(NSArray<NSString *> *)userIDs;

/**
 远端用户离开房间事件。
 
 @param demo ZGVideoTalkDemo 实例
 @param userIDs 远端用户 ID 列表
 */
- (void)demo:(ZGJoinLiveDemo *)demo remoteUserLeaveLiveRoom:(NSArray<NSString *> *)userIDs;

@end


/**
 直播连麦 VM 类。瘦身 ViewController，抽象直播连麦的逻辑并封装为接口和属性，简化整个交互流程。
 
 它的基本使用流程为：
 1.使用 initWithAppID 初始化，初始化成功后，后续的其他方法才能有效使用。
 2.使用 joinLiveRoom 进入直播房间，使用 leaveLiveRoom 退出直播房间
 3.通过代理的 demo:remoteUserOnLiveUpdated:withUserIDs: 方法获取远端用户的加入和退出连麦的通知，在界面上做相应 UI 的处理，以及调用 VM 的 playRemoteUserLive: 进行远端用户直播的播放, stopRemoteUserLive: 进行播放停止
 
 @discussion 简化 SDK 对于直播连麦业务的一系列接口，用户可以参考该类实现构建自己的业务。
 @note 开发者可参考该类的代码, 理解直播连麦涉及的 SDK 接口
 */
@interface ZGJoinLiveDemo : NSObject

// 是否启用相机
@property (nonatomic, readonly) BOOL enableCamera;

// 是否启用麦克风
@property (nonatomic, readonly) BOOL enableMic;

// 加入房间状态
@property (nonatomic, readonly) ZGJoinLiveDemoJoinRoomState joinRoomState;

// 加入的房间 id
@property (nonatomic, readonly) NSString *joinRoomID;

// 本地用户是否在直播（连麦）
@property (nonatomic, readonly) BOOL localOnLive;

// 本地用户直播的推流 ID
@property (nonatomic, readonly) NSString *localLiveStreamID;

// 本地用户 ID
@property (nonatomic, readonly) NSString *localUserID;

// 参与连麦的远程用户 ID 列表
@property (nonatomic, readonly) NSArray<NSString *> *remoteLiveUserIDList;

@property (nonatomic, weak) id<JoinLiveDemoDataSource> dataSource;
@property (nonatomic, weak) id<JoinLiveDemoDelegate> delegate;

- (instancetype)init NS_UNAVAILABLE;

/**
 初始化 JoinLiveDemo 实例。
 
 @param appID appID
 @param appSign appSign
 @param completionBlock 初始化回调。errorCode == 0 表示成功。
 @return 是否初始化成功
 */
- (instancetype)initWithAppID:(unsigned int)appID
                      appSign:(NSData *)appSign
              completionBlock:(void(^)(ZGJoinLiveDemo *demo, int errorCode))completionBlock;

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
 加入连麦房间。初始化回调的 errorCode == 0 时设置才有效。
 
 @param roomID 房间 ID。根据业务取系统唯一值
 @param userID 用户 ID。根据业务取系统惟一值，最好有意义
 @param isAnchor 是否为主播
 @param callback 回调。errorCode： 为 0 表示加入成功。joinLiveUserIDs：房间内已加入到连麦的用户 ID 列表
 @return 请求是否发送成功
 */
- (BOOL)joinLiveRoom:(NSString *)roomID
              userID:(NSString *)userID
            isAnchor:(BOOL)isAnchor
            callback:(void(^)(int errorCode, NSArray<NSString *> *joinLiveUserIDs))callback;

/**
 离开连麦房间。初始化回调的 errorCode == 0 时设置才有效。
 
 @return 是否成功
 */
- (BOOL)leaveLiveRoom;

/**
 开启本地用户直播。
 
 此时会通过 dataSource 的 localUserLiveStreamID: 方法获取直播推流 ID，通过 localUserLivePreviewView: 获取本地用户预览渲染视图进行直播设置。
 */
- (void)startLocalUserLive;

/**
 关闭本地用户直播
 */
- (void)stopLocalUserLive;

/**
 播放远端用户的直播。
 
 此时会通过 dataSource 的 demo:livePlayViewForRemoteUser: 方法获取该远端用户直播的渲染视图进行播放设置。

 @param remoteUserID 远端用户 ID
 */
- (void)playRemoteUserLive:(NSString *)remoteUserID;

/**
 停止播放远端用户直播

 @param remoteUserID 远端用户 ID
 */
- (void)stopRemoteUserLive:(NSString *)remoteUserID;

@end

NS_ASSUME_NONNULL_END

#endif
