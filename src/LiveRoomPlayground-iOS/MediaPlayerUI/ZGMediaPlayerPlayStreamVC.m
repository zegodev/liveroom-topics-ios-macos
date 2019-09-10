//
//  ZGMediaPlayerPlayStreamVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/23.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_MediaPlayer

#import "ZGMediaPlayerPlayStreamVC.h"
#import <ZegoLiveRoom/ZegoLiveRoomApi.h>
#import "ZGAppGlobalConfigManager.h"
#import "ZGAppSignHelper.h"
#import "ZGUserIDHelper.h"

@interface ZGMediaPlayerPlayStreamVC () <ZegoLivePlayerDelegate>

@property (nonatomic) ZegoLiveRoomApi *zegoApi;

@end

@implementation ZGMediaPlayerPlayStreamVC

+ (instancetype)instanceFromStoryboard {
    return [[UIStoryboard storyboardWithName:@"NewMediaPlayer" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass([ZGMediaPlayerPlayStreamVC class])];
}

- (void)dealloc {
    NSLog(@"%@ dealloc.", [self class]);
    
    [_zegoApi stopPlayingStream:self.streamID];
    [_zegoApi logoutRoom];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"拉流";
    [self startPlayLive];
}

- (void)startPlayLive {
    ZGAppGlobalConfig *appConfig = [[ZGAppGlobalConfigManager sharedInstance] globalConfig];
    
    // 设置 SDK 环境，需要在 init SDK 之前设置，后面调用 SDK 的 api 才能在该环境内执行
    [ZegoLiveRoomApi setUseTestEnv:(appConfig.environment == ZGAppEnvironmentTest)];
    [ZegoLiveRoomApi setVideoCaptureFactory:nil];
    
    // init SDK
    ZGLogInfo(@"请求初始化");
    self.zegoApi = [[ZegoLiveRoomApi alloc] initWithAppID:(unsigned int)appConfig.appID appSignature:[ZGAppSignHelper convertAppSignFromString:appConfig.appSign] completionBlock:^(int errorCode) {
        if (errorCode != 0) {
            ZGLogWarn(@"初始化失败，errorCode:%d", errorCode);
        } else {
            ZGLogInfo(@"初始化成功");
        }
    }];
    if (!self.zegoApi) {
        ZGLogWarn(@"初始化失败，请检查参数是否正确");
    } else {
        // 设置 SDK 相关代理
        [self.zegoApi setPlayerDelegate:self];
    }
    
    // 获取 userID，userName 并设置到 SDK 中。必须在 loginRoom 之前设置，否则会出现登录不进行回调的问题
    // 这里演示简单将时间戳作为 userID，将 userID 和 userName 设置成一样。实际使用中可以根据需要，设置成业务相关的 userID
    NSString *userID = ZGUserIDHelper.userID;
    [ZegoLiveRoomApi setUserID:userID userName:userID];
    
    // 登录房间
    Weakify(self);
    [ZegoHudManager showNetworkLoading];
    BOOL reqResult = [_zegoApi loginRoom:self.roomID role:ZEGO_AUDIENCE withCompletionBlock:^(int errorCode, NSArray<ZegoStream *> *streamList) {
        Strongify(self);
        [ZegoHudManager hideNetworkLoading];
        
        if (errorCode != 0) {
            ZGLogWarn(@"登录房间失败,errorCode:%d", errorCode);
            // 登录房间失败
            [ZegoHudManager showMessage:[NSString stringWithFormat:@"登录房间失败,errorCode:%d", errorCode]];
            return;
        }
        
        ZGLogInfo(@"登录房间成功");
        
        // 登录房间成功
        // 开始拉流
        [self startPlayStream];
    }];
    if (reqResult) {
        ZGLogInfo(@"请求登录房间");
    } else {
        ZGLogWarn(@"请求登录房间失败");
    }
}

- (void)startPlayStream {
    NSString *streamID = self.streamID;
    if (streamID) {
        // 开始拉流, 在 ZegoLivePlayerDelegate
        ZGLogInfo(@"开始拉流，streamID: %@", streamID);
        self.navigationItem.title = @"拉流请求...";
        [self.zegoApi startPlayingStream:streamID inView:self.view];
        [self.zegoApi setViewMode:ZegoVideoViewModeScaleAspectFit ofStream:streamID];
    }
}

#pragma mark - ZegoLivePlayerDelegate

- (void)onPlayStateUpdate:(int)stateCode streamID:(NSString *)streamID {
    // 播放流状态回调
    if (stateCode == 0) {
        ZGLogInfo(@"拉流成功，streamID:%@", streamID);
        self.navigationItem.title = @"拉流成功";
    } else {
        ZGLogWarn(@"拉流失败，streamID:%@，stateCode:%d", streamID, stateCode);
        self.navigationItem.title = @"拉流失败";
    }
}

- (void)onPlayQualityUpate:(NSString *)streamID quality:(ZegoApiPlayQuality)quality {
    // 观看质量更新
    NSLog(@"拉流质量。fps:%f,videoBitrate:%f, quanlity:%d", quality.fps, quality.kbps, quality.quality);
}

@end
#endif
