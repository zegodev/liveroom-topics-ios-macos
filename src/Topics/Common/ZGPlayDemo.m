//
//  ZGPlayDemo.m
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/5/15.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_Play

#import "ZGPlayDemo.h"
#import "ZGLoginRoomDemo.h"

@interface ZGPlayDemo () <ZegoLivePlayerDelegate>

@property (assign, nonatomic) BOOL isPlaying;

@property (copy, nonatomic) NSString *streamID;

@property (weak, nonatomic) ZEGOView *playView;

@end

@implementation ZGPlayDemo

+ (instancetype)shared {
    static id instance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        [instance setupBind];
    });
    
    //拉流代理很重要, 开发者可以按自己的需求在回调里实现自己的 App 相关业务。
    //回调介绍请参考文档 https://doc.zego.im/CN/216.html
    [ZGApiManager.api setPlayerDelegate:instance];
    
    return instance;
}

/**
 开始拉流

 @param streamID 同一房间内对应推流端的 streamID, SDK 基于 streamID 进行拉流
 @param view 用于渲染视频的 view
 @return 调用是否成功
 @discussion 拉流常见问题：https://doc.zego.im/CN/491.html
 @note 注意!!! 每个用户的流名必须保持唯一，也就是流名必须 AppID 内全局唯一。
 @note 注意!!! 登陆房间后才能使用拉流接口，该接口要与 -stopPublishing 成对使用。
 */
- (BOOL)startPlayingStream:(NSString *)streamID inView:(ZEGOView *)view {
    if (self.isPlaying) {
        return NO;
    }
    
    ZGLogInfo(@"开始拉流,流名:%@,预览视图:%@",streamID, view);
    
    bool result = [ZGApiManager.api startPlayingStream:streamID inView:view];
    
    if (result) {
        self.streamID = streamID;
    }
    else {
        ZGLogWarn(@"拉流出错，参数不合法");
    }
    
    return result ? YES:NO;
}

/**
 停止拉流
 */
- (void)stopPlay {
    if (!self.isPlaying) {
        return;
    }
    
    ZGLogInfo(@"结束拉流:%@",self.streamID);
    
    [ZGApiManager.api stopPlayingStream:self.streamID];
    
    self.isPlaying = NO;
    self.streamID = nil;
}

/**
 设置播放视图
 
 @param view 要设置的播放视图，SDK 会把拉流获取到的数据渲染到 view 上
 */
- (void)updatePlayView:(ZEGOView *)view {
    if (!self.isPlaying || [view isEqual:self.playView]) {
        return;
    }
    
    ZGLogInfo(@"设置播放视图:%@,流ID:%@",view, self.streamID);
    
    [ZGApiManager.api updatePlayView:view ofStream:self.streamID];
    self.playView = view;
}

- (void)updatePlayViewMode:(ZegoVideoViewMode)mode {
    if (!self.isPlaying) {
        return;
    }
    
    ZGLogInfo(@"设置播放视图模式:%d,流ID:%@",mode, self.streamID);
    
    [ZGApiManager.api setViewMode:mode ofStream:self.streamID];
}

#pragma mark - Bind

- (void)setupBind {
    ZGLoginRoomDemo *loginDemo = ZGLoginRoomDemo.shared;
    [self bind:loginDemo keyPath:ZGBindKeyPath(loginDemo.isLoginRoom) action:@selector(onLoginStateChange)];
}

- (void)onLoginStateChange {
    if (!ZGLoginRoomDemo.shared.isLoginRoom) {
        self.isPlaying = NO;
        self.streamID = nil;
    }
}

#pragma mark - PlayerDelegate
// 拉流回调文档说明: https://doc.zego.im/API/ZegoLiveRoom/iOS/html/Protocols/ZegoLivePlayerDelegate.html

- (void)onPlayStateUpdate:(int)stateCode streamID:(NSString *)streamID {
    BOOL success = stateCode == 0;
    
    self.isPlaying = success;
    
    if (success) {
        ZGLogInfo(@"拉流成功，流Id:%@",streamID);
    }
    else {
        ZGLogError(@"拉流出错，流Id:%@，错误码:%d",streamID,stateCode);
        self.streamID = nil;
    }
    
    [self.delegate onPlayStateUpdate:stateCode streamID:streamID];
}

- (void)onInviteJoinLiveRequest:(int)seq fromUserID:(NSString *)userId fromUserName:(NSString *)userName roomID:(NSString *)roomID {
    // 当观众收到主播端的邀请连麦请求时，会调用此方法
    // 开发者想要深入了解连麦业务请参考文档: https://doc.zego.im/CN/223.html
    
    ZGLogInfo(@"收到邀请连麦，seq:%d,userID:%@,userName:%@,roomID:%@",seq, userId, userName, roomID);
}

- (void)onEndJoinLiveCommad:(NSString *)fromUserId userName:(NSString *)fromUserName roomID:(NSString *)roomID {
    // 当观众收到主播端的结束连麦请求时，会调用此方法
    // 开发者想要深入了解连麦业务请参考文档: https://doc.zego.im/CN/223.html
    
    ZGLogInfo(@"收到结束连麦，fromUserID:%@,fromUserName:%@,roomID:%@",fromUserId, fromUserName, roomID);
}

- (void)onVideoSizeChangedTo:(CGSize)size ofStream:(NSString *)streamID {
    // startPlay 后，以下情况下，播放端会收到该通知：
    // 1. SDK 在获取到第一帧数据后
    // 2. 直播过程中视频宽高发生变化。从播放第一条流，到获得第一帧数据，中间可能出现一个短暂的时间差（具体时长取决于当前的网络状态）。
    // 推荐在进入直播页面时加载一张预览图以提升用户体验，然后在本回调中去掉预览图
    
    ZGLogDebug(@"拉流视频分辨率变化,w:%f,h:%f,streamID:%@", size.width, size.height, streamID);
}

- (void)onPlayQualityUpate:(NSString *)streamID quality:(ZegoApiPlayQuality)quality {
    //拉流质量更新, 回调频率默认3秒一次
    //可通过 -setPlayQualityMonitorCycle: 修改回调频率
    
    ZGLogDebug(@"拉流质量回调,streamID:%@,fps:%f,videoBitrate:%f,audioBitrate:%f",streamID, quality.fps, quality.kbps, quality.akbps);
    
    if ([self.delegate respondsToSelector:@selector(onPlayQualityUpdate:quality:)]) {
        [self.delegate onPlayQualityUpdate:streamID quality:quality];
    }
}

@end

#endif
