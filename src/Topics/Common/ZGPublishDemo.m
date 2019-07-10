//
//  ZGPublishDemo.m
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/4/24.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_Publish

#import "ZGPublishDemo.h"
#import "ZGLoginRoomDemo.h"

@interface ZGPublishDemo () <ZegoLivePublisherDelegate>

@property (assign, nonatomic) BOOL isPreview;
@property (assign, nonatomic) BOOL isPublishing;

@property (copy, nonatomic) NSString *streamID;

@property (weak, nonatomic) ZEGOView *previewVieww;

@end

@implementation ZGPublishDemo

+ (instancetype)shared {
    static id instance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        [instance setupBind];
    });
    
    //推流代理很重要, 开发者可以按自己的需求在回调里实现自己的 App 相关业务。
    //回调介绍请参考文档 https://doc.zego.im/CN/208.html
    [ZGApiManager.api setPublisherDelegate:instance];
    
    return instance;
}

/**
 开始推流
 
 @param streamID 流ID，不能为空，只支持长度不超过 256 byte 的数字、下划线、字母。
 @param title 流标题，长度不可超过 255 byte。
 @param flag 发布直播的模式, 详见 ZegoAPIPublishFlag
 @discussion 推流常见问题：https://doc.zego.im/CN/490.html
 @note 注意!!! 每个用户的流名必须保持唯一，也就是流名必须 AppID 内全局唯一。
 @note 注意!!! 登陆房间后才能使用推流接口，该接口要与 -stopPublishing 成对使用。
 */
- (BOOL)startPublish:(NSString *)streamID title:(NSString *)title flag:(int)flag {
    if (self.isPublishing) {
        return NO;
    }
    
    ZGLogInfo(@"开始推流,流名:%@,title:%@,flag:%d",streamID, title, flag);
    
    bool result = [ZGApiManager.api startPublishing:streamID title:title flag:flag];
    
    if (result) {
        self.streamID = streamID;
    }
    else {
        ZGLogWarn(@"推流出错，参数不合法");
    }
    
    return result ? YES:NO;
}

- (void)stopPublish {
    if (!self.isPublishing) {
        return;
    }
    
    ZGLogInfo(@"结束推流:%@",self.streamID);
    
    [ZGApiManager.api stopPublishing];
    
    self.isPublishing = NO;
    self.streamID = nil;
}

/**
 开始预览
 */
- (void)startPreview {
    if (self.isPreview) {
        return;
    }
    
    ZGLogInfo(@"开始预览");
    
    [ZGApiManager.api startPreview];
    
    self.isPreview = YES;
}

/**
 结束预览
 */
- (void)stopPreview {
    if (!self.isPreview) {
        return;
    }
    
    ZGLogInfo(@"结束预览");
    
    [ZGApiManager.api stopPreview];
    
    self.isPreview = NO;
}

/**
 设置渲染视图

 @param view 要设置的渲染视图，SDK 会把采集到的数据渲染到 view 上
 */
- (void)setPreviewView:(ZEGOView *)view {
    if ([view isEqual:self.previewVieww]) {
        return;
    }
    
    ZGLogInfo(@"设置预览视图:%@",view);
    
    [ZGApiManager.api setPreviewView:view];
    self.previewVieww = view;
}

#pragma mark - Bind

- (void)setupBind {
    ZGLoginRoomDemo *loginDemo = ZGLoginRoomDemo.shared;
    [self bind:loginDemo keyPath:ZGBindKeyPath(loginDemo.isLoginRoom) action:@selector(onLoginStateChange)];
}

- (void)onLoginStateChange {
    if (!ZGLoginRoomDemo.shared.isLoginRoom) {
        self.isPublishing = NO;
        self.streamID = nil;
    }
}

#pragma mark - PublisherDelegate
// 推流回调文档说明: https://doc.zego.im/API/ZegoLiveRoom/iOS/html/Protocols/ZegoLivePublisherDelegate.html

- (void)onPublishStateUpdate:(int)stateCode streamID:(NSString *)streamID streamInfo:(NSDictionary *)info {
    // 推流状态更新，errorCode 非0 则说明推流成功
    // 推流常见错误码请看文档: https://doc.zego.im/CN/308.html
    
    BOOL success = stateCode == 0;
    
    self.isPublishing = success;
    
    if (success) {
        ZGLogInfo(@"推流成功，流Id:%@",streamID);
    }
    else {
        ZGLogError(@"推流出错，流Id:%@，错误码:%d",streamID,stateCode);
        self.streamID = nil;
    }
    
    [self.delegate onPublishStateUpdate:stateCode streamID:streamID streamInfo:info];
}

- (void)onJoinLiveRequest:(int)seq fromUserID:(NSString *)userId fromUserName:(NSString *)userName roomID:(NSString *)roomID {
    //房间内有人申请加入连麦时会回调该方法
    //观众端可通过 - requestJoinLive: 方法申请加入连麦
    
    ZGLogInfo(@"请求加入连麦，seq:%d,userID:%@,userName:%@,roomID:%@",seq, userId, userName, roomID);
}

- (void)onPublishQualityUpdate:(NSString *)streamID quality:(ZegoApiPublishQuality)quality {
    //推流质量更新, 回调频率默认3秒一次
    //可通过 -setPublishQualityMonitorCycle: 修改回调频率
    
    ZGLogDebug(@"推流质量回调,streamID:%@,fps:%f,videoBitrate:%f,audioBitrate:%f",streamID, quality.fps, quality.kbps, quality.akbps);
    
    if ([self.delegate respondsToSelector:@selector(onPublishQualityUpdate:quality:)]) {
        [self.delegate onPublishQualityUpdate:streamID quality:quality];
    }
}

- (void)onCaptureVideoSizeChangedTo:(CGSize)size {
    // 当采集时分辨率有变化时，sdk会回调该方法
    
    ZGLogDebug(@"推流采集分辨率变化,w:%f,h:%f", size.width, size.height);
}

- (void)onMixStreamConfigUpdate:(int)errorCode mixStream:(NSString *)mixStreamID streamInfo:(NSDictionary *)info {
    // 混流配置更新时会回调该方法。
}

- (void)onAuxCallback:(void *)pData dataLen:(int *)pDataLen sampleRate:(int *)pSampleRate channelCount:(int *)pChannelCount {
    // 可以将外部音乐混进推流中。类似于直播中添加伴奏，掌声等音效
    // 另外还能用于 KTV 场景中的伴奏播放
    // 想深入了解可以进入进阶功能中的混音专题。
    // https://doc.zego.im/CN/252.html 文档中有说明
}

- (void)onRelayCDNStateUpdate:(NSArray<ZegoAPIStreamRelayCDNInfo *> *)statesInfo streamID:(NSString*)streamID {
    //转推CDN状态信息更新
}

@end

#endif
