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
@property (nonatomic, assign) BOOL apiInitialized;
@property (nonatomic, assign) ZGVideoTalkDemoRoomLoginState roomLoginState;
@property (nonatomic, copy) NSString *talkRoomID;
@property (nonatomic, assign) BOOL onPublishLocalStream;
@property (nonatomic, copy) NSString *localStreamID;
@property (nonatomic, copy) NSString *localUserID;

// 本地用户的预览视图缓存
@property (nonatomic, weak) UIView *localUserVideoPreviewView;

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
    }
    else {
        ZGLogWarn(@"Failed enableCamera to %@", boolStr);
    }
}

- (BOOL)joinTalkRoom:(NSString *)talkRoomID
              userID:(NSString *)userID
            streamID:(NSString *)streamID
            callback:(void(^)(int errorCode))callback {
    if (talkRoomID.length == 0 || userID.length == 0 || streamID.length == 0) {
        ZGLogWarn(@"必填参数不能为空！");
        return NO;
    }
    
    if (![self checkApiInitialized]) {
        return NO;
    }
    
    if (self.roomLoginState != ZGVideoTalkDemoRoomLoginStateNotLogin) {
        ZGLogWarn(@"已登录或正在登录，不可重复请求登录。");
        return NO;
    }
    
    self.talkRoomID = talkRoomID;
    self.localUserID = userID;
    [self updateRoomLoginState:ZGVideoTalkDemoRoomLoginStateOnRequestLogin];
    
    // 设置 ZegoLiveRoomApi 的 userID 和 userName。在登录前必须设置，否则会调用 loginRoom 会返回 NO。
    // 业务根据需要设置有意义的 userID 和 userName。当前 demo 没有特殊需要，可设置为一样
    [ZegoLiveRoomApi setUserID:userID userName:userID];
    
    Weakify(self);
    BOOL result = [self.zegoApi loginRoom:talkRoomID role:ZEGO_ANCHOR withCompletionBlock:^(int errorCode, NSArray<ZegoStream *> *streamList) {
        Strongify(self);
        
        ZGLogInfo(@"登录房间，errorCode:%d, 房间号:%@, 流数量:%@", errorCode, talkRoomID, @([streamList count]));
        
        BOOL isLoginSuccess = errorCode == 0;
        self.talkRoomID = talkRoomID;
        [self updateRoomLoginState:isLoginSuccess ? ZGVideoTalkDemoRoomLoginStateHasLogin : ZGVideoTalkDemoRoomLoginStateNotLogin];
        
        if (isLoginSuccess) {
            [self addRemoteUserStreams:streamList];
            
            // 开启推流
            [self startPublishing:streamID];
            
            // 必要时开启预览
            if (self.localUserVideoPreviewView) {
                [self.zegoApi startPreview];
            }
        }
        
        if (callback) {
            callback(errorCode);
        }
    }];
    if (!result) {
        [self updateRoomLoginState:ZGVideoTalkDemoRoomLoginStateNotLogin];
        self.talkRoomID = nil;
    }
    return result;
}

- (BOOL)leaveTalkRoom {
    if (![self checkApiInitialized]) {
        return NO;
    }
    
    if (self.roomLoginState != ZGVideoTalkDemoRoomLoginStateHasLogin) {
        ZGLogWarn(@"未登录房间，无需离开房间。");
        return NO;
    }
    
    [self.zegoApi stopPreview];
    [self stopPublishing];
    BOOL result = [self.zegoApi logoutRoom];
    if (result) {
        [self onLogout];
    }
    return result;
}

- (void)setLocalUserVideoPreviewView:(UIView *)previewView {
    if (![self checkApiInitialized]) {
        return;
    }
    
    if (_localUserVideoPreviewView != previewView) {
        [self.zegoApi stopPreview];
        [self.zegoApi setPreviewView:previewView];
        [self.zegoApi startPreview];
        _localUserVideoPreviewView = previewView;
    }
}

- (void)startPlayRemoteUserVideo:(NSString *)userID inView:(UIView *)playView {
    if (userID.length == 0) {
        ZGLogWarn(@"userID 不能为空！");
        return;
    }
    
    if (![self checkApiInitialized]) {
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

- (void)stopPlayRemoteUserVideo:(NSString *)userID {
    if (userID.length == 0) {
        ZGLogWarn(@"userID 不能为空！");
        return;
    }
    
    if (![self checkApiInitialized]) {
        return;
    }
    
    ZegoStream *existStream = [self getTalkStreamInCurrentListWithUserID:userID];
    if (existStream) {
        [self.zegoApi stopPlayingStream:existStream.streamID];
    }
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

- (void)addRemoteUserStreams:(NSArray<ZegoStream *> *)streams {
    if (streams == nil) {
        return;
    }
    
    for (ZegoStream *stream in streams) {
        // 添加新的 stream
        [self.remoteUserStreams addObject:stream];
    }
    
    // 修改 joinTalkUserIDList
    self.remoteUserIDList = [[self.remoteUserStreams copy] valueForKeyPath:@"userID"];
}

- (void)removeRemoteUserStreams:(NSArray<ZegoStream *> *)streams {
    if (streams == nil) {
        return;
    }
    
    for (ZegoStream *stream in streams) {
        ZegoStream *existObj = [self getTalkStreamInCurrentListWithStreamID:stream.streamID];
        // 删除已有相同的 stream
        if (existObj) {
            [self.remoteUserStreams removeObject:existObj];
        }
    }
    
    // 修改 joinTalkUserIDList
    self.remoteUserIDList = [[self.remoteUserStreams copy] valueForKeyPath:@"userID"];
}

- (BOOL)checkApiInitialized {
    if (self.apiInitialized) {
        return YES;
    }
    
    ZGLogWarn(@"ZegoLiveRoomApi 未初始化");
    return NO;
}

- (void)onLogout {
    [self updateRoomLoginState:ZGVideoTalkDemoRoomLoginStateNotLogin];
    self.talkRoomID = nil;
    [self.remoteUserStreams removeAllObjects];
    self.remoteUserIDList = nil;
}

- (void)startPublishing:(NSString *)streamID {
    if ([self.zegoApi startPublishing:streamID title:nil flag:ZEGO_JOIN_PUBLISH]) {
        self.localStreamID = streamID;
    }
}

- (void)stopPublishing {
    if ([self.zegoApi stopPublishing]) {
        self.localStreamID = nil;
        [self updateOnPublishLocalStream:NO];
    }
}

- (void)updateRoomLoginState:(ZGVideoTalkDemoRoomLoginState)state {
    self.roomLoginState = state;
    NSString *roomID = self.talkRoomID;
    if ([self.delegate respondsToSelector:@selector(videoTalkDemo:roomLoginStateUpdated:roomID:)]) {
        [self.delegate videoTalkDemo:self roomLoginStateUpdated:state roomID:roomID];
    }
}

- (void)updateOnPublishLocalStream:(BOOL)onPublish {
    self.onPublishLocalStream = onPublish;
    if ([self.delegate respondsToSelector:@selector(videoTalkDemo:localUserOnPublishVideoUpdated:)]) {
        [self.delegate videoTalkDemo:self localUserOnPublishVideoUpdated:onPublish];
    }
}

#pragma mark - ZegoRoomDelegate

- (void)onKickOut:(int)reason roomID:(NSString *)roomID {
    
    ZGLogWarn(@"被踢出房间，原因:%d，房间号:%@",reason, roomID);
    
    if (![roomID isEqualToString:self.talkRoomID]) {
        return;
    }
    
    [self.zegoApi stopPreview];
    [self stopPublishing];
    [self onLogout];
    
    if ([self.delegate respondsToSelector:@selector(videoTalkDemo:kickOutTalkRoom:)]) {
        [self.delegate videoTalkDemo:self kickOutTalkRoom:roomID];
    }
}

- (void)onDisconnect:(int)errorCode roomID:(NSString *)roomID {
    
    ZGLogWarn(@"房间连接断开，错误码:%d，房间号:%@",errorCode, roomID);
    
    if (![roomID isEqualToString:self.talkRoomID]) {
        return;
    }
    
    [self.zegoApi stopPreview];
    [self stopPublishing];
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
    
    BOOL isTypeAdd = type == ZEGO_STREAM_ADD;//流变更类型：增加/删除
    
    for (ZegoStream *stream in streamList) {
        ZGLogInfo(@"收到流更新:%@，类型:%@，房间号:%@",stream.streamID, isTypeAdd ? @"增加":@"删除", roomID);
    }
    
    if (![roomID isEqualToString:self.talkRoomID]) {
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
        if (isTypeAdd) {
            if ([self.delegate respondsToSelector:@selector(videoTalkDemo:didJoinTalkRoom:withUserIDs:)]) {
                [self.delegate videoTalkDemo:self didJoinTalkRoom:roomID withUserIDs:userIDs];
            }
        }
        else {
            if ([self.delegate respondsToSelector:@selector(videoTalkDemo:didLeaveTalkRoom:withUserIDs:)]) {
                [self.delegate videoTalkDemo:self didLeaveTalkRoom:roomID withUserIDs:userIDs];
            }
        }
    }
}

- (void)onStreamExtraInfoUpdated:(NSArray<ZegoStream *> *)streamList roomID:(NSString *)roomID {
    for (ZegoStream *stream in streamList) {
        ZGLogInfo(@"收到流附加信息更新:%@，流ID:%@，房间号:%@",stream.extraInfo, stream.streamID, roomID);
    }
}


#pragma mark - ZegoLivePublisherDelegate

- (void)onPublishStateUpdate:(int)stateCode streamID:(NSString *)streamID streamInfo:(NSDictionary *)info {
    // 推流状态更新，errorCode 非0 则说明推流成功
    // 推流常见错误码请看文档: https://doc.zego.im/CN/308.html
    
    BOOL success = stateCode == 0;
    if (success) {
        ZGLogInfo(@"推流成功，流Id:%@",streamID);
    }
    else {
        ZGLogError(@"推流出错，流Id:%@，错误码:%d",streamID,stateCode);
    }
    
    [self updateOnPublishLocalStream:success];
}

- (void)onPublishQualityUpdate:(NSString *)streamID quality:(ZegoApiPublishQuality)quality {
    //推流质量更新, 回调频率默认3秒一次
    //可通过 -setPublishQualityMonitorCycle: 修改回调频率
   ZGLogDebug(@"推流质量更新，streamID:%@,cfps:%d,kbps:%d,acapFps:%d,akbps:%d,rtt:%d,pktLostRate:%d,quality:%d",
             streamID,(int)quality.cfps,(int)quality.kbps,
             (int)quality.acapFps,(int)quality.akbps,
             quality.rtt,quality.pktLostRate,quality.quality);
}

- (void)onCaptureVideoSizeChangedTo:(CGSize)size {
    // 当采集时分辨率有变化时，sdk会回调该方法
    ZGLogDebug(@"推流采集分辨率变化,w:%f,h:%f", size.width, size.height);
}

#pragma mark - ZegoLivePlayerDelegate

- (void)onPlayStateUpdate:(int)stateCode streamID:(NSString *)streamID {
    if (stateCode == 0) {
        ZGLogInfo(@"拉流成功，流Id:%@",streamID);
    }
    else {
        ZGLogError(@"拉流出错，流Id:%@，错误码:%d",streamID,stateCode);
    }
    
    ZegoStream *existStream = [self getTalkStreamInCurrentListWithStreamID:streamID];
    if (existStream &&
        [self.delegate respondsToSelector:@selector(videoTalkDemo:remoteUserVideoStateUpdate:withUserID:)]) {
        [self.delegate videoTalkDemo:self remoteUserVideoStateUpdate:stateCode withUserID:existStream.userID];
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

@end

#endif
