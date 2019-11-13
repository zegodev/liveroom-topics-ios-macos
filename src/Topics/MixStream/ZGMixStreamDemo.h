//
//  ZGMixStreamDemo.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/19.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_MixStream

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 示例加入房间状态
 
 - ZGMixStreamDemoJoinRoomStateNotJoin: 还未加入
 - ZGMixStreamDemoJoinRoomStateOnRequestJoin: 请求加入中
 - ZGMixStreamDemoJoinRoomStateHasJoin: 已加入
 */
typedef NS_ENUM(NSUInteger, ZGMixStreamDemoJoinRoomState) {
    ZGMixStreamDemoJoinRoomStateNotJoin,
    ZGMixStreamDemoJoinRoomStateOnRequestJoin,
    ZGMixStreamDemoJoinRoomStateHasJoin
};

@class ZGMixStreamDemo;
@class ZegoMixStreamConfig;
@class ZegoStream;

@protocol ZGMixStreamDemoDataSource <NSObject>
@required

/**
 获取本地用户直播的推流 ID
 
 @param demo ZGMixStreamDemo 实例
 @return 推流 ID
 */
- (NSString *)localUserLiveStreamID:(ZGMixStreamDemo *)demo;

@optional

/**
 在本地直播推流开始后，获取是否更新推流的附加信息

 @param demo ZGMixStreamDemo 实例
 @param streamInfo 流信息，可以通过内置 zego 内置的一些 key 获取相关信息
 @return bool 结果
 */
- (BOOL)shouldUpdateLocalLiveStreamExtraInfoOnPublishStarted:(ZGMixStreamDemo *)demo streamInfo:(NSDictionary *)streamInfo;

/**
 本地直播推流开始后，获取要更新的附加信息，然后进行更新

 @param demo ZGMixStreamDemo 实例
 @param streamInfo 流信息，可以通过内置 zego 内置的一些 key 获取相关信息
 @return 附加信息
 */
- (NSString *)localLiveStreamExtraInfoToUpdateOnPublishStarted:(ZGMixStreamDemo *)demo streamInfo:(NSDictionary *)streamInfo;

/**
 获取本地用户直播视频预览的渲染视图
 
 @param demo ZGMixStreamDemo 实例
 @return 渲染视图
 */
- (UIView *)localUserLivePreviewView:(ZGMixStreamDemo *)demo;

/**
 获取远端用户的直播播放的渲染视图
 
 @param demo ZGMixStreamDemo 实例
 @param userLiveStreamID 远端用户直播 stream ID
 @return 渲染视图
 */
- (UIView *)demo:(ZGMixStreamDemo *)demo livePlayViewForRemoteUserWithStreamID:(NSString *)userLiveStreamID;

/**
 获取进行混流的流 ID。
 
 为了在混流时的获取到混流的 stream ID，在启用混流后将会调用本方法。
 
 @param demo ZGMixStreamDemo 实例
 @return 混流 ID
 */
- (NSString *)liveMixStreamID:(ZGMixStreamDemo *)demo;

/**
 获取进行混流的配置
 
 为了在混流时的获取到混流的配置，在启用混流后将会调用本方法。
 
 @param demo ZGMixStreamDemo 实例
 @param mixStreamID 混流 ID
 @return 混流 ID
 */
- (ZegoMixStreamConfig *)demo:(ZGMixStreamDemo *)demo liveMixStreamConfigForMixStream:(NSString *)mixStreamID;

@end

@protocol ZGMixStreamDemoDelegate <NSObject>
@optional

/**
 本地用户被踢出房间事件。若有相同 userID 用户登录同一房间，则先登录的用户会被踢出。
 
 @param demo ZGMixStreamDemo 实例
 @param roomID 直播房间 ID
 */
- (void)demo:(ZGMixStreamDemo *)demo kickOutRoom:(NSString *)roomID;

/**
 断开房间连接事件。
 
 @param demo ZGMixStreamDemo 实例
 @param roomID 直播房间 ID
 */
- (void)demo:(ZGMixStreamDemo *)demo disConnectRoom:(NSString *)roomID;

/**
 本地用户直播状态变化事件。
 
 @param demo ZGMixStreamDemo 实例
 @param onLive 是否在直播（连麦）
 */
- (void)demo:(ZGMixStreamDemo *)demo localUserOnLiveUpdated:(BOOL)onLive;

/**
 远端用户直播状态变化事件。
 
 @param demo ZGMixStreamDemo 实例
 @param onLive 是否在直播（连麦）
 @param liveStreams 远端用户直播 stream 列表
 */
- (void)demo:(ZGMixStreamDemo *)demo remoteUserOnLiveUpdated:(BOOL)onLive withLiveStreams:(NSArray<ZegoStream*> *)liveStreams;

/**
 远端用户视频状态变化事件。
 
 @param demo ZGMixStreamDemo 实例
 @param stateCode 状态码。stateCode != 0 表示发生错误。发生错误后，用户可实现自己的逻辑，如显示错误信息和暂停状态，然后显示播放按钮实现重新播放
 @param liveStreamID 直播流 ID
 */
- (void)demo:(ZGMixStreamDemo *)demo remoteUserLivePlayStateUpdate:(int)stateCode
  withLiveStreamID:(NSString *)liveStreamID;


/**
 远端用户加入房间事件。
 
 @param demo ZGMixStreamDemo 实例
 @param userIDs 远端用户 ID 列表
 */
- (void)demo:(ZGMixStreamDemo *)demo remoteUserJoinLiveRoom:(NSArray<NSString *> *)userIDs;

/**
 远端用户离开房间事件。
 
 @param demo ZGMixStreamDemo 实例
 @param userIDs 远端用户 ID 列表
 */
- (void)demo:(ZGMixStreamDemo *)demo remoteUserLeaveLiveRoom:(NSArray<NSString *> *)userIDs;

/**
 混流状态变化事件。

 @param demo ZGMixStreamDemo 实例
 @param onMixStream 当前混流状态
 @param mixStreamID 混流 ID
 */
- (void)demo:(ZGMixStreamDemo *)demo onMixStreamUpdated:(BOOL)onMixStream mixStreamID:(NSString *)mixStreamID;

@end


/**
 多路混流 VM 类。瘦身 ViewController，抽象多路混流的逻辑并封装为接口和属性，简化整个交互流程。
 
 它的基本使用流程为：
 1.使用 initWithAppID 初始化，初始化成功后，后续的其他方法才能有效使用。
 2.使用 joinLiveRoom 进入直播房间，使用 leaveLiveRoom 退出直播房间
 3.使用 startLocalUserLive, stopLocalUserLive 开始活停止本地直播，方法内部会调用数据源（dataSource）相应方法获取数据进行直播设置。
 4.提供远端用户直播状态变化的代理方法，UI 可根据需要处理，如进行直播视图的增加和删除。
 5.使用 playRemoteUserLiveWithStreamID:, stopRemoteUserLiveWithStreamID: 方法开始或停止播放远端用户的直播，方法内部会调用数据源获取相应方法获取数据进行播放设置。
 6.使用 startOrUpdateMixStream, stopCurrentMixStream 进行混流的控制，方法内部会调用数据源的相应方法获取数据进行混流配置。
 
 @discussion 简化 SDK 对于直播连麦业务的一系列接口，用户可以参考该类实现构建自己的业务。
 @note 开发者可参考该类的代码, 理解直播连麦涉及的 SDK 接口
 */
@interface ZGMixStreamDemo : NSObject

// 是否启用相机
@property (nonatomic, readonly) BOOL enableCamera;

// 是否启用麦克风
@property (nonatomic, readonly) BOOL enableMic;

// 加入房间状态
@property (nonatomic, readonly) ZGMixStreamDemoJoinRoomState joinRoomState;

// 加入的房间 id
@property (nonatomic, readonly) NSString *joinRoomID;

// 本地用户是否在直播（连麦）
@property (nonatomic, readonly) BOOL localOnLive;

// 本地用户直播的推流 ID
@property (nonatomic, readonly) NSString *localLiveStreamID;

// 本地用户 ID
@property (nonatomic, readonly) NSString *localUserID;

// 参与连麦的远程用户的流列表
@property (nonatomic, readonly) NSArray<ZegoStream *> *remoteUserLiveStreams;

// 当前混流 ID
@property (nonatomic, readonly) NSString *currentMixStreamID;

// 是否正在混流
@property (nonatomic, readonly) BOOL onMixStream;

@property (nonatomic, weak) id<ZGMixStreamDemoDataSource> dataSource;
@property (nonatomic, weak) id<ZGMixStreamDemoDelegate> delegate;


- (instancetype)init NS_UNAVAILABLE;

/**
 初始化 ZGMixStreamDemo 实例。
 
 @param appID appID
 @param appSign appSign
 @param completionBlock 初始化回调。errorCode == 0 表示成功。
 @return 是否初始化成功
 */
- (instancetype)initWithAppID:(unsigned int)appID
                      appSign:(NSData *)appSign
              completionBlock:(void(^)(ZGMixStreamDemo *demo, int errorCode))completionBlock;

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
 @param callback 回调。errorCode 为 0 表示加入成功。joinLiveStreams：房间内已加入连麦的用户流列表
 @return 请求是否发送成功
 */
- (BOOL)joinLiveRoom:(NSString *)roomID
              userID:(NSString *)userID
            isAnchor:(BOOL)isAnchor
            callback:(void(^)(int errorCode, NSArray<ZegoStream *> *joinLiveStreams))callback;

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
 
 此时会通过 dataSource 的 demo:livePlayViewForRemoteUserWithStreamID: 方法获取该远端用户直播的渲染视图进行播放设置。
 
 @param userLiveStreamID 远端用户直播 stream ID
 */
- (void)playRemoteUserLiveWithStreamID:(NSString *)userLiveStreamID;

/**
 停止播放远端用户直播。
 
 @param userLiveStreamID 远端用户直播 stream ID
 */
- (void)stopRemoteUserLiveWithStreamID:(NSString *)userLiveStreamID;


/**
 开始或更新混流。
 
 此方法用以实现混流，在 demo:localUserOnLiveUpdated:，demo:remoteUserOnLiveUpdated:withLiveStreams: 回调后调用 startOrUpdateMixStream 进行混流更新。此时会通过 dataSource 的 liveMixStreamID: 获取混流 ID，通过 demo:liveMixStreamConfig: 获取混流配置开始或更新混流
 */
- (void)startOrUpdateMixStream;

/**
 停止当前混流。
 */
- (void)stopCurrentMixStream;

@end

NS_ASSUME_NONNULL_END

#endif
