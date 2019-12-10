//
//  JoinLiveDemo.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/11.
//  Copyright © 2019 Zego. All rights reserved.
//

#if defined(_Module_JoinLive) || defined(_Module_RoomConfigLive)

#import "ZGJoinLiveDemo.h"
#import <ZegoLiveRoom/ZegoLiveRoomApi-IM.h>

@interface ZGJoinLiveDemo () <ZegoRoomDelegate, ZegoLivePublisherDelegate, ZegoLivePlayerDelegate, ZegoIMDelegate>

@property (nonatomic, assign) BOOL audienceCreateRoomEnabled;
@property (nonatomic, assign) BOOL enableCamera;
@property (nonatomic, assign) BOOL enableMic;
@property (nonatomic, assign) BOOL apiInitialized;
@property (nonatomic, assign) ZGJoinLiveDemoJoinRoomState joinRoomState;
@property (nonatomic, copy) NSString *joinRoomID;
@property (nonatomic, assign) BOOL localOnLive;
@property (nonatomic, copy) NSString *localLiveStreamID;
@property (nonatomic, copy) NSString *localUserID;
@property (nonatomic, copy) NSArray<NSString *> *remoteLiveUserIDList;

// 远程用户的流列表
@property (nonatomic) NSMutableArray<ZegoStream *> *remoteUserStreams;

@property (nonatomic, strong) ZegoLiveRoomApi *zegoApi;

@end

@implementation ZGJoinLiveDemo

#pragma mark - public methods

- (instancetype)initWithAppID:(unsigned int)appID
                      appSign:(NSData *)appSign
              completionBlock:(void(^)(ZGJoinLiveDemo *demo, int errorCode))completionBlock {
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
            [api setIMDelegate:self];
            // 设置是否可以监控房间其他用户的登录或离开
            [api setRoomConfig:self.audienceCreateRoomEnabled userStateUpdate:YES];
        }
        
        self.zegoApi = api;
    }
    return self;
}

- (void)setAudienceCreateRoomEnabled:(BOOL)audienceCreateRoomEnabled {
    if (![self checkApiInitialized]) {
        return;
    }
    
    _audienceCreateRoomEnabled = audienceCreateRoomEnabled;
    [self.zegoApi setRoomConfig:audienceCreateRoomEnabled userStateUpdate:YES];
    NSString *boolStr = audienceCreateRoomEnabled?@"YES":@"NO";
    ZGLogInfo(@"enableMic:%@", boolStr);
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
    }
    else {
        ZGLogWarn(@"Failed enableCamera to %@", boolStr);
    }
}

- (BOOL)joinLiveRoom:(NSString *)roomID
              userID:(NSString *)userID
            isAnchor:(BOOL)isAnchor
            callback:(void(^)(int errorCode, NSArray<NSString *> *joinLiveUserIDs))callback {
    if (roomID.length == 0 || userID.length == 0) {
        ZGLogWarn(@"必填参数不能为空！");
        return NO;
    }
    
    if (![self checkApiInitialized]) {
        return NO;
    }
    
    if (self.joinRoomState != ZGJoinLiveDemoJoinRoomStateNotJoin) {
        ZGLogWarn(@"已登录或正在登录，不可重复请求登录。");
        return NO;
    }
    
    self.joinRoomID = roomID;
    self.localUserID = userID;
    self.joinRoomState = ZGJoinLiveDemoJoinRoomStateOnRequestJoin;
    
    // 设置 ZegoLiveRoomApi 的 userID 和 userName。在登录前必须设置，否则会调用 loginRoom 会返回 NO。
    // 业务根据需要设置有意义的 userID 和 userName。当前 demo 没有特殊需要，可设置为一样
    [ZegoLiveRoomApi setUserID:userID userName:userID];
    
    Weakify(self);
    BOOL result = [self.zegoApi loginRoom:roomID role:isAnchor?ZEGO_ANCHOR:ZEGO_AUDIENCE withCompletionBlock:^(int errorCode, NSArray<ZegoStream *> *streamList) {
        Strongify(self);
        
        ZGLogInfo(@"登录房间，errorCode:%d, 房间号:%@, 流数量:%@", errorCode, roomID, @([streamList count]));
        
        BOOL loginSuccess = errorCode == 0;
        NSArray<NSString *> *joinLiveUserIDs = nil;
        if (loginSuccess) {
            joinLiveUserIDs = [streamList valueForKeyPath:@"userID"];
            self.joinRoomState = ZGJoinLiveDemoJoinRoomStateHasJoin;
            [self addRemoteUserStreams:streamList];
        }
        else {
            self.joinRoomState = ZGJoinLiveDemoJoinRoomStateNotJoin;
        }
        
        if (callback) {
            callback(errorCode, joinLiveUserIDs);
        }
    }];
    
    if (!result) {
        self.joinRoomState = ZGJoinLiveDemoJoinRoomStateNotJoin;
        self.joinRoomID = nil;
        self.localUserID = nil;
    }
    
    return result;
}

- (BOOL)leaveLiveRoom {
    if (![self checkApiInitialized]) {
        return NO;
    }
    
    if (self.joinRoomState != ZGJoinLiveDemoJoinRoomStateHasJoin) {
        ZGLogWarn(@"未登录房间，无需离开房间。");
        return NO;
    }
    
    [self internalStopLocalUserLive];
    BOOL result = [self.zegoApi logoutRoom];
    if (result) {
        [self onLogout];
    }
    return result;
}

- (void)startLocalUserLive {
    if (![self checkApiInitialized]) {
        return;
    }
    
    NSString *streamID = [self.dataSource localUserLiveStreamID:self];
    if (streamID.length == 0) {
        ZGLogWarn(@"开始本地直播推流，但是 streamID 为空，本次发起推流无效");
        return;
    }
    
    [self internalStartLocalUserLivePreview];
    if ([self.zegoApi startPublishing:streamID title:nil flag:ZEGO_JOIN_PUBLISH]) {
        self.localLiveStreamID = streamID;
    }
}

- (void)stopLocalUserLive {
    if (![self checkApiInitialized]) {
        return;
    }
    
    NSString *localStreamID = self.localLiveStreamID;
    if (localStreamID.length == 0) {
        ZGLogWarn(@"不存在本地直播推流，无需停止");
        return;
    }
    
    [self internalStopLocalUserLive];
}

- (void)playRemoteUserLive:(NSString *)remoteUserID {
    if (![self checkApiInitialized]) {
        return;
    }
    
    UIView *renderView = [self.dataSource demo:self livePlayViewForRemoteUser:remoteUserID];
    if (renderView == nil) {
        ZGLogWarn(@"未获取到远端用户 live 播放渲染视图，本次播放请求无效。remoteUserID: %@", remoteUserID);
        return;
    }
    
    ZegoStream *stream = [self getStreamInCurrentListWithUserID:remoteUserID];
    if (stream) {
        [self.zegoApi stopPlayingStream:stream.streamID];
        [self.zegoApi startPlayingStream:stream.streamID inView:renderView];
    }
}

- (void)stopRemoteUserLive:(NSString *)remoteUserID {
    if (![self checkApiInitialized]) {
        return;
    }
    ZegoStream *stream = [self getStreamInCurrentListWithUserID:remoteUserID];
    if (stream) {
        [self internalStopPlayStreamWithID:stream.streamID];
    }
}

#pragma mark - private methods

- (void)internalStartLocalUserLivePreview {
    UIView *renderView = [self.dataSource localUserLivePreviewView:self];
    if (!renderView) {
        ZGLogWarn(@"未获取到本地用户的预览渲染视图，本次开启预览请求无效。");
        return;
    }
    
    [self.zegoApi setPreviewView:renderView];
    [self.zegoApi startPreview];
}

- (void)internalStopLocalUserLivePreview {
    [self.zegoApi stopPreview];
}

- (void)internalStopPlayStreamWithID:(NSString *)streamID {
    [self.zegoApi stopPlayingStream:streamID];
}

- (ZegoStream *)getStreamInCurrentListWithUserID:(NSString *)userID {
    __block ZegoStream *existStream = nil;
    [self.remoteUserStreams enumerateObjectsUsingBlock:^(ZegoStream * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.userID isEqualToString:userID]) {
            existStream = obj;
            *stop = YES;
        }
    }];
    return existStream;
}

- (ZegoStream *)getStreamInCurrentListWithStreamID:(NSString *)streamID {
    __block ZegoStream *existStream = nil;
    [self.remoteUserStreams enumerateObjectsUsingBlock:^(ZegoStream * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.streamID isEqualToString:streamID]) {
            existStream = obj;
            *stop = YES;
        }
    }];
    return existStream;
}

- (void)addRemoteUserStreams:(NSArray<ZegoStream *> *)streams {
    if (streams == nil) {
        return;
    }
    
    for (ZegoStream *stream in streams) {
        // 添加新的 stream
        [self.remoteUserStreams addObject:stream];
    }
    
    self.remoteLiveUserIDList = [[self.remoteUserStreams copy] valueForKeyPath:@"userID"];
}

- (void)removeRemoteUserStreams:(NSArray<ZegoStream *> *)streams {
    if (streams == nil) {
        return;
    }
    
    for (ZegoStream *stream in streams) {
        ZegoStream *existObj = [self getStreamInCurrentListWithStreamID:stream.streamID];
        // 删除已有相同的 stream
        if (existObj) {
            [self.remoteUserStreams removeObject:existObj];
            [self internalStopPlayStreamWithID:stream.streamID];
        }
    }
    
    self.remoteLiveUserIDList = [[self.remoteUserStreams copy] valueForKeyPath:@"userID"];
}

- (BOOL)checkApiInitialized {
    if (self.apiInitialized) {
        return YES;
    }
    
    ZGLogWarn(@"ZegoLiveRoomApi 未初始化");
    return NO;
}

- (void)onLogout {
    self.joinRoomState = ZGJoinLiveDemoJoinRoomStateNotJoin;
    self.joinRoomID = nil;
    [self.remoteUserStreams removeAllObjects];
    self.remoteLiveUserIDList = nil;
}

- (void)updateLocalOnLive:(BOOL)localOnLive {
    self.localOnLive = localOnLive;
    if ([self.delegate respondsToSelector:@selector(demo:localUserOnLiveUpdated:)]) {
        [self.delegate demo:self localUserOnLiveUpdated:localOnLive];
    }
}

- (void)internalStopLocalUserLive {
    if ([self.zegoApi stopPublishing]) {
        [self internalStopLocalUserLivePreview];
        self.localLiveStreamID = nil;
        [self updateLocalOnLive:NO];
    }
}

#pragma mark - ZegoRoomDelegate

- (void)onKickOut:(int)reason roomID:(NSString *)roomID {
    // 该用户被踢出房间的通知；有另外的设备用同样的 userID 登录了相同的房间，造成前面登录的用户被踢出房间，或者后台调用踢人接口将此用户踢出房间；App 应提示用户被踢出房间。
    // 注意：业务侧要确保分配的 userID 保持唯一，不然会造成互相抢占。
    
    ZGLogWarn(@"被踢出房间，原因:%d，房间号:%@",reason, roomID);
    
    if (![roomID isEqualToString:self.joinRoomID]) {
        return;
    }
    
    [self internalStopLocalUserLive];
    [self onLogout];
    
    if ([self.delegate respondsToSelector:@selector(demo:kickOutRoom:)]) {
        [self.delegate demo:self kickOutRoom:roomID];
    }
}

- (void)onDisconnect:(int)errorCode roomID:(NSString *)roomID {
    // 房间与 ZEGO 服务器断开连接的通知；一般在断网并在自动重连90秒后，依旧没有恢复网络时会收到这个回调，此时推流/拉流都会断开；App 端需要检测网络，在正常联网时重新登录房间，重新推流/拉流。
    
    ZGLogWarn(@"房间连接断开，错误码:%d，房间号:%@",errorCode, roomID);
    
    if (![roomID isEqualToString:self.joinRoomID]) {
        return;
    }
    
    [self internalStopLocalUserLive];
    [self onLogout];
    
    if ([self.delegate respondsToSelector:@selector(demo:disConnectRoom:)]) {
        [self.delegate demo:self disConnectRoom:roomID];
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
    
    if (![roomID isEqualToString:self.joinRoomID]) {
        return;
    }
    
    if (isTypeAdd) {
        [self addRemoteUserStreams:streamList];
    }
    else {
        [self removeRemoteUserStreams:streamList];
    }
    
    NSArray<NSString *> *userIDs = [[streamList valueForKeyPath:@"userID"] copy];
    if (userIDs.count > 0) {
        if ([self.delegate respondsToSelector:@selector(demo:remoteUserOnLiveUpdated:withUserIDs:)]) {
            [self.delegate demo:self remoteUserOnLiveUpdated:isTypeAdd withUserIDs:userIDs];
        }
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
    
    [self updateLocalOnLive:success];
}

- (void)onPublishQualityUpdate:(NSString *)streamID quality:(ZegoApiPublishQuality)quality {
    //推流质量更新, 回调频率默认3秒一次
    //可通过 -setPublishQualityMonitorCycle: 修改回调频率
    ZGLogDebug(@"推流质量更新，streamID:%@,cfps:%d,kbps:%d,acapFps:%d,akbps:%d,rtt:%d,pktLostRate:%d,quality:%d",
               streamID,(int)quality.cfps,(int)quality.kbps,
               (int)quality.acapFps,(int)quality.akbps,
               quality.rtt,quality.pktLostRate,quality.quality);
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
    
    ZegoStream *existStream = [self getStreamInCurrentListWithStreamID:streamID];
    if (existStream &&
        [self.delegate respondsToSelector:@selector(demo:remoteUserLivePlayStateUpdate:withUserID:)]) {
        [self.delegate demo:self remoteUserLivePlayStateUpdate:stateCode withUserID:existStream.userID];
    }
}

- (void)onPlayQualityUpate:(NSString *)streamID quality:(ZegoApiPlayQuality)quality {
    //拉流质量更新, 回调频率默认3秒一次
    //可通过 -setPlayQualityMonitorCycle: 修改回调频率
    ZGLogDebug(@"拉流质量更新，streamID:%@,vrndFps:%d,kbps:%d,arndFps:%d,akbps:%d,rtt:%d,pktLostRate:%d,quality:%d",
               streamID,(int)quality.vrndFps,(int)quality.kbps,
               (int)quality.arndFps,(int)quality.akbps,
               quality.rtt,quality.pktLostRate,quality.quality);
}

#pragma mark - ZegoIMDelegate

- (void)onUserUpdate:(NSArray<ZegoUserState *> *)userList updateType:(ZegoUserUpdateType)type {
    // 房间成员更新回调，当房间成员变化（例如用户进入、退出房间）时，会触发此通知
    if (self.joinRoomState != ZGJoinLiveDemoJoinRoomStateHasJoin) {
        return;
    }
    
    NSMutableArray<NSString *> *joinRoomUserIDs = [NSMutableArray<NSString *> array];
    NSMutableArray<NSString *> *leaveRoomUserIDs = [NSMutableArray<NSString *> array];
    [userList enumerateObjectsUsingBlock:^(ZegoUserState * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.updateFlag == ZEGO_USER_ADD) {
            [joinRoomUserIDs addObject:obj.userID];
        }
        else if (obj.updateFlag == ZEGO_USER_DELETE) {
            [leaveRoomUserIDs addObject:obj.userID];
        }
    }];
    
    if (joinRoomUserIDs.count > 0 && [self.delegate respondsToSelector:@selector(demo:remoteUserJoinLiveRoom:)]) {
        [self.delegate demo:self remoteUserJoinLiveRoom:[joinRoomUserIDs copy]];
    }
    
    if (leaveRoomUserIDs.count > 0 && [self.delegate respondsToSelector:@selector(demo:remoteUserLeaveLiveRoom:)]) {
        [self.delegate demo:self remoteUserLeaveLiveRoom:[leaveRoomUserIDs copy]];
    }
}

@end

#endif
