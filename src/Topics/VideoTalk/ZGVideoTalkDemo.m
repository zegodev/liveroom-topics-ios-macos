//
//  ZGVideoTalkDemo.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/3.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_VideoTalk

#import "ZGVideoTalkDemo.h"

@interface ZGVideoTalkDemo () <ZegoRoomDelegate, ZegoLivePublisherDelegate, ZegoLivePlayerDelegate>

@property (nonatomic, assign) BOOL enableCamera;
@property (nonatomic, assign) BOOL enableMic;
@property (nonatomic, assign) BOOL enableAudioModule;
@property (nonatomic, assign) BOOL apiInitialized;
@property (nonatomic, assign) ZGVideoTalkJoinRoomState joinRoomState;
@property (nonatomic, copy) NSString *talkRoomID;
@property (nonatomic, copy) NSString *localStreamID;
@property (nonatomic, copy) NSString *localUserID;

// 参与通话的远程用户 ID 列表
@property (nonatomic, copy) NSArray<NSString *> *remoteUserIDList;

// 远程用户的流列表
@property (nonatomic) NSMutableArray<ZegoStream *> *remoteUserStreams;

@property (nonatomic, strong) ZegoLiveRoomApi *zegoApi;

@end

@implementation ZGVideoTalkDemo

#pragma mark - public methods

- (instancetype)initWithAppID:(unsigned int)appID
                      appSign:(NSData *)appSign
              completionBlock:(void(^)(ZGVideoTalkDemo *demo, int errorCode))completionBlock {
    if (appSign == nil) {
        ZGLogWarn(@"appSign 不能为空。");
        return nil;
    }
    
    if (self = [super init]) {
        self.remoteUserStreams = [NSMutableArray<ZegoStream *> array];

        __weak typeof(self) weakSelf = self;
        ZegoLiveRoomApi *api = [[ZegoLiveRoomApi alloc] initWithAppID:appID appSignature:appSign completionBlock:^(int errorCode) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            
            if (strongSelf) {
                strongSelf.apiInitialized = errorCode == 0;
            }
            
            ZGLogInfo(@"初始化 zego api，errorCode:%d", errorCode);
            if (completionBlock) {
                completionBlock(strongSelf, errorCode);
            }
        }];
        
        if (api) {
            [api setRoomDelegate:self];
            [api setPublisherDelegate:self];
            [api setPlayerDelegate:self];
        }
        
        self.zegoApi = api;
    }
    return self;
}

- (void)setEnableMic:(BOOL)enableMic {
    if (![self checkApiInitialized]) {
        return;
    }
    
    NSString *boolStr = enableMic?@"YES":@"NO";
    if ([self.zegoApi enableMic:enableMic]) {
        ZGLogInfo(@"enableMic:%@", boolStr);
        _enableMic = enableMic;
    }
    else {
        ZGLogWarn(@"Failed enableMic to %@", boolStr);
    }
}

- (void)setEnableCamera:(BOOL)enableCamera {
    if (![self checkApiInitialized]) {
        return;
    }
    
    NSString *boolStr = enableCamera?@"YES":@"NO";
    if ([self.zegoApi enableCamera:enableCamera]) {
        ZGLogInfo(@"enableCamera:%@", boolStr);
        _enableCamera = enableCamera;
    } else {
        ZGLogWarn(@"Failed enableCamera to %@", boolStr);
    }
}

- (void)setEnableAudioModule:(BOOL)enableAudioModule {
    if (![self checkApiInitialized]) {
        return;
    }
    
    _enableAudioModule = enableAudioModule;
    if (enableAudioModule) {
        [self.zegoApi resumeModule:ZEGOAPI_MODULE_AUDIO];
        ZGLogInfo(@"resume audio Module");
    } else {
        [self.zegoApi pauseModule:ZEGOAPI_MODULE_AUDIO];
        ZGLogInfo(@"pause audio Module");
    }
}

- (BOOL)joinTalkRoom:(NSString *)talkRoomID
              userID:(NSString *)userID
            callback:(void(^)(int errorCode, NSArray<NSString *> *joinTalkUserIDs))callback {
    if (talkRoomID.length == 0 || userID.length == 0) {
        ZGLogWarn(@"必填参数不能为空！");
        return NO;
    }
    
    if (![self checkApiInitialized]) {
        return NO;
    }
    
    if (self.joinRoomState != ZGVideoTalkJoinRoomStateNotJoin) {
        ZGLogWarn(@"已登录或正在登录，不可重复请求登录。");
        return NO;
    }
    
    self.talkRoomID = talkRoomID;
    self.localUserID = userID;
    [self updateLocalUserJoinRoomState:ZGVideoTalkJoinRoomStateOnRequestJoin];
    
    // 设置 ZegoLiveRoomApi 的 userID 和 userName。在登录前必须设置，否则会调用 loginRoom 会返回 NO。
    // 业务根据需要设置有意义的 userID 和 userName。当前 demo 没有特殊需要，可设置为一样
    [ZegoLiveRoomApi setUserID:userID userName:userID];
    
    Weakify(self);
    BOOL result = [self.zegoApi loginRoom:talkRoomID role:ZEGO_ANCHOR withCompletionBlock:^(int errorCode, NSArray<ZegoStream *> *streamList) {
        Strongify(self);
        
        ZGLogInfo(@"登录房间，errorCode:%d, 房间号:%@, 流数量:%@", errorCode, talkRoomID, @([streamList count]));
        
        BOOL isLoginSuccess = errorCode == 0;
        NSArray<NSString *> *joinTalkUserIDs = nil;
        [self updateLocalUserJoinRoomState:isLoginSuccess?ZGVideoTalkJoinRoomStateJoined:ZGVideoTalkJoinRoomStateNotJoin];
        
        if (isLoginSuccess) {
            joinTalkUserIDs = [streamList valueForKeyPath:@"userID"];
            // 直接加入通话
            [self internalJoinTalk];
            [self addRemoteUserTalkStreams:streamList];
        }
        if (callback) {
            callback(errorCode, joinTalkUserIDs);
        }
    }];
    if (!result) {
        self.talkRoomID = nil;
        self.localUserID = nil;
        [self updateLocalUserJoinRoomState:ZGVideoTalkJoinRoomStateNotJoin];
    }
    return result;
}

- (BOOL)leaveTalkRoom {
    if (![self checkApiInitialized]) {
        return NO;
    }
    
    if (self.joinRoomState != ZGVideoTalkJoinRoomStateJoined) {
        ZGLogWarn(@"未登录房间，无需离开房间。");
        return NO;
    }
    
    [self internalLeaveTalk];
    BOOL result = [self.zegoApi logoutRoom];
    if (result) {
        [self onLogout];
    }
    return result;
}

#pragma mark - private methods

- (ZegoStream *)getTalkStreamInCurrentListWithUserID:(NSString *)userID {
    __block ZegoStream *existStream = nil;
    [self.remoteUserStreams enumerateObjectsUsingBlock:^(ZegoStream * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.userID isEqualToString:userID]) {
            existStream = obj;
            *stop = YES;
        }
    }];
    return existStream;
}

- (ZegoStream *)getTalkStreamInCurrentListWithStreamID:(NSString *)streamID {
    __block ZegoStream *existStream = nil;
    [self.remoteUserStreams enumerateObjectsUsingBlock:^(ZegoStream * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.streamID isEqualToString:streamID]) {
            existStream = obj;
            *stop = YES;
        }
    }];
    return existStream;
}

- (BOOL)checkApiInitialized {
    if (self.apiInitialized) {
        return YES;
    }
    
    ZGLogWarn(@"ZegoLiveRoomApi 未初始化");
    return NO;
}

- (void)onLogout {
    [self updateLocalUserJoinRoomState:ZGVideoTalkJoinRoomStateNotJoin];
    self.talkRoomID = nil;
    [self.remoteUserStreams removeAllObjects];
    self.remoteUserIDList = nil;
}

- (void)internalJoinTalk {
    // 获取 streamID
    NSString *streamID = [self.dataSource localUserJoinTalkStreamID:self];
    if (streamID.length == 0) {
        ZGLogWarn(@"加入通话失败，dataSource 未提供 streamID.");
        return;
    }
    
    // 获取预览视图，开始预览
    UIView *previewView = [self.dataSource localUserPreviewView:self];
    [self.zegoApi setPreviewView:previewView];
    [self.zegoApi startPreview];
    
    // 发布推流
    if ([self.zegoApi startPublishing:streamID title:nil flag:ZEGO_JOIN_PUBLISH]) {
        self.localStreamID = streamID;
    }
}

- (void)internalLeaveTalk {
    // 停止预览
    [self.zegoApi setPreviewView:nil];
    [self.zegoApi stopPreview];
    
    // 停止推流
    if ([self.zegoApi stopPublishing]) {
        self.localStreamID = nil;
    }
}

- (void)internalStartPlayRemoteUserTalkWithUserID:(NSString *)userID {
    UIView *playView = [self.dataSource videoTalkDemo:self playViewForRemoteUserWithID:userID];
    if (playView == nil) {
        ZGLogWarn(@"播放远端用户通话失败，dataSource 未用户的播放视图, userID: %@", userID);
        return;
    }
    
    if (playView) {
        // 若当前流列表存在目标用户的通话流，则更新视频播放视图
        ZegoStream *existStream = [self getTalkStreamInCurrentListWithUserID:userID];
        if (existStream) {
            [self.zegoApi startPlayingStream:existStream.streamID inView:playView];
        }
    }
}

- (void)addRemoteUserTalkStreams:(NSArray<ZegoStream *> *)streams {
    if (streams == nil) {
        return;
    }
    
    // 添加新的 stream
    for (ZegoStream *stream in streams) {
        [self.remoteUserStreams addObject:stream];
    }
    
    // 修改 joinTalkUserIDList
    self.remoteUserIDList = [[self.remoteUserStreams copy] valueForKeyPath:@"userID"];
    
    
    // 调用代理
    NSString *roomID = self.talkRoomID;
    NSArray<NSString*> *addUserIDs = [streams valueForKeyPath:@"userID"];
    if ([self.delegate respondsToSelector:@selector(videoTalkDemo:remoteUserDidJoinTalkInRoom:userIDs:)]) {
        [self.delegate videoTalkDemo:self remoteUserDidJoinTalkInRoom:roomID userIDs:addUserIDs];
    }
    
    // 播放通话
    for (NSString *userID in addUserIDs) {
        [self internalStartPlayRemoteUserTalkWithUserID:userID];
    }
}

- (void)removeRemoteUserTalkStreamWithIDs:(NSArray<NSString *> *)streamIDs {
    if (streamIDs == nil) {
        return;
    }
    
    // 删除已有 stream
    NSMutableArray<ZegoStream*> *rmStreams = [NSMutableArray array];
    for (NSString *streamID in streamIDs) {
        ZegoStream *existObj = [self getTalkStreamInCurrentListWithStreamID:streamID];
        if (existObj) {
            [self.remoteUserStreams removeObject:existObj];
            [rmStreams addObject:existObj];
        }
        // 停止拉流
        [self.zegoApi stopPlayingStream:streamID];
    }
    
    // 修改 joinTalkUserIDList
    self.remoteUserIDList = [[self.remoteUserStreams copy] valueForKeyPath:@"userID"];
    
    
    NSString *roomID = self.talkRoomID;
    NSArray<NSString*> *rmUserIDs = [rmStreams valueForKeyPath:@"userID"];
    if (rmUserIDs.count > 0) {
        // 调用代理
        if ([self.delegate respondsToSelector:@selector(videoTalkDemo:remoteUserDidLeaveTalkInRoom:userIDs:)]) {
            [self.delegate videoTalkDemo:self remoteUserDidLeaveTalkInRoom:roomID userIDs:rmUserIDs];
        }
    }
}


- (void)updateLocalUserJoinRoomState:(ZGVideoTalkJoinRoomState)state {
    self.joinRoomState = state;
    NSString *roomID = self.talkRoomID;
    if ([self.delegate respondsToSelector:@selector(videoTalkDemo:localUserJoinRoomStateUpdated:roomID:)]) {
        [self.delegate videoTalkDemo:self localUserJoinRoomStateUpdated:state roomID:roomID];
    }
}

#pragma mark - ZegoRoomDelegate

- (void)onKickOut:(int)reason roomID:(NSString *)roomID {
    // 该用户被踢出房间的通知；有另外的设备用同样的 userID 登录了相同的房间，造成前面登录的用户被踢出房间，或者后台调用踢人接口将此用户踢出房间；App 应提示用户被踢出房间。
    // 注意：业务侧要确保分配的 userID 保持唯一，不然会造成互相抢占。
    
    ZGLogWarn(@"被踢出房间，原因:%d，房间号:%@",reason, roomID);
    
    if (![roomID isEqualToString:self.talkRoomID]) {
        return;
    }
    
    [self internalLeaveTalk];
    [self onLogout];
    
    if ([self.delegate respondsToSelector:@selector(videoTalkDemo:kickOutTalkRoom:)]) {
        [self.delegate videoTalkDemo:self kickOutTalkRoom:roomID];
    }
}

- (void)onDisconnect:(int)errorCode roomID:(NSString *)roomID {
    // 房间与 ZEGO 服务器断开连接的通知；一般在断网并在自动重连90秒后，依旧没有恢复网络时会收到这个回调，此时推流/拉流都会断开；App 端需要检测网络，在正常联网时重新登录房间，重新推流/拉流。
    
    ZGLogWarn(@"房间连接断开，错误码:%d，房间号:%@",errorCode, roomID);
    
    if (![roomID isEqualToString:self.talkRoomID]) {
        return;
    }
    
    [self internalLeaveTalk];
    [self onLogout];
    
    if ([self.delegate respondsToSelector:@selector(videoTalkDemo:disConnectTalkRoom:)]) {
        [self.delegate videoTalkDemo:self disConnectTalkRoom:roomID];
    }
}

- (void)onTempBroken:(int)errorCode roomID:(NSString *)roomID {
    ZGLogWarn(@"房间与 Server 中断，SDK会尝试自动重连，房间号:%@",roomID);
}

- (void)onReconnect:(int)errorCode roomID:(NSString *)roomID {
    ZGLogInfo(@"房间与 Server 重新连接，房间号:%@",roomID);
}

- (void)onStreamUpdated:(int)type streams:(NSArray<ZegoStream *> *)streamList roomID:(NSString *)roomID {
    // 房间内流变化回调。房间内增加流、删除流，均会触发此回调，主播推流自己不会收到此回调，房间内其他成员会收到。
    
    BOOL isTypeAdd = type == ZEGO_STREAM_ADD;//流变更类型：增加/删除
    
    for (ZegoStream *stream in streamList) {
        ZGLogInfo(@"收到流更新:%@，类型:%@，房间号:%@",stream.streamID, isTypeAdd ? @"增加":@"删除", roomID);
    }
    
    if (![roomID isEqualToString:self.talkRoomID]) {
        return;
    }
    
    if (isTypeAdd) {
        [self addRemoteUserTalkStreams:streamList];
    } else {
        NSArray<NSString *> *streamIDs = [streamList valueForKeyPath:@"streamID"];
        [self removeRemoteUserTalkStreamWithIDs:streamIDs];
    }
}


#pragma mark - ZegoLivePublisherDelegate

- (void)onPublishStateUpdate:(int)stateCode streamID:(NSString *)streamID streamInfo:(NSDictionary *)info {
    // 推流状态更新，errorCode == 0 则说明推流成功，否则失败
    // 推流常见错误码请看文档: https://doc.zego.im/CN/308.html#3
    
    BOOL success = stateCode == 0;
    if (success) {
        ZGLogInfo(@"推流成功，流Id:%@",streamID);
    }
    else {
        ZGLogError(@"推流出错，流Id:%@，错误码:%d",streamID,stateCode);
    }
}

- (void)onPublishQualityUpdate:(NSString *)streamID quality:(ZegoApiPublishQuality)quality {
    //推流质量更新, 回调频率默认3秒一次
    //可通过 -setPublishQualityMonitorCycle: 修改回调频率
  /* ZGLogDebug(@"推流质量更新，streamID:%@,cfps:%d,kbps:%d,acapFps:%d,akbps:%d,rtt:%d,pktLostRate:%d,quality:%d",
             streamID,(int)quality.cfps,(int)quality.kbps,
             (int)quality.acapFps,(int)quality.akbps,
             quality.rtt,quality.pktLostRate,quality.quality);
   */
}

#pragma mark - ZegoLivePlayerDelegate

- (void)onPlayStateUpdate:(int)stateCode streamID:(NSString *)streamID {
    // 拉流是否成功或者拉流成功后断网等错误导致拉流失败的通知，如果拉流失败（stateCode!=0），App 端提示拉流失败或者重试拉流，相关错误码请查看 https://doc.zego.im/CN/308.html#4
    if (stateCode == 0) {
        ZGLogInfo(@"拉流成功，流Id:%@",streamID);
    }
    else {
        ZGLogError(@"拉流出错，流Id:%@，错误码:%d",streamID,stateCode);
    }
    
    ZegoStream *existStream = [self getTalkStreamInCurrentListWithStreamID:streamID];
    if (existStream &&
        [self.delegate respondsToSelector:@selector(videoTalkDemo:remoteUserVideoStateUpdate:userID:)]) {
        [self.delegate videoTalkDemo:self remoteUserVideoStateUpdate:stateCode userID:existStream.userID];
    }
}

- (void)onPlayQualityUpate:(NSString *)streamID quality:(ZegoApiPlayQuality)quality {
    //拉流质量更新, 回调频率默认3秒一次
    //可通过 -setPlayQualityMonitorCycle: 修改回调频率

   /* ZGLogDebug(@"拉流质量更新，streamID:%@,vrndFps:%d,kbps:%d,arndFps:%d,akbps:%d,rtt:%d,pktLostRate:%d,quality:%d",
               streamID,(int)quality.vrndFps,(int)quality.kbps,
               (int)quality.arndFps,(int)quality.akbps,
               quality.rtt,quality.pktLostRate,quality.quality);
    */
}

/**
 远端摄像头状态通知
 */
- (void)onRemoteCameraStatusUpdate:(int)status ofStream:(NSString *)streamID {
    ZGLogInfo(@"远端摄像头状态变化, status:%d", status);
}

/**
 远端麦克风状态通知
 */
- (void)onRemoteMicStatusUpdate:(int)status ofStream:(NSString *)streamID {
     ZGLogInfo(@"远端mic状态变化, status:%d", status);
}

@end

#endif
