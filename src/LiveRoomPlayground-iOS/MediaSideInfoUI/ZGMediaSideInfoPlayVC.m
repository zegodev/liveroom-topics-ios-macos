//
//  ZGMediaSideInfoPlayVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/21.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_MediaSideInfo

#import "ZGMediaSideInfoPlayVC.h"
#import "ZGAppGlobalConfigManager.h"
#import "ZGAppSignHelper.h"
#import "ZGMediaSideInfoDemo.h"

@interface ZGMediaSideInfoPlayVC () <ZegoLivePlayerDelegate, ZGMediaSideInfoDemoDelegate>

@property (weak, nonatomic) IBOutlet UIView *playLiveView;
@property (weak, nonatomic) IBOutlet UITextView *sideInfoTextView;

@property (nonatomic) ZegoLiveRoomApi *zegoApi;
@property (nonatomic) ZGMediaSideInfoDemo *mediaSideInfoController;

@end

@implementation ZGMediaSideInfoPlayVC

+ (instancetype)instanceFromStoryboard {
    return [[UIStoryboard storyboardWithName:@"MediaSideInfo" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass([ZGMediaSideInfoPlayVC class])];
}

- (void)dealloc {
    NSLog(@"%@ dealloc.", [self class]);
    
    [self.zegoApi stopPlayingStream:self.streamID];
    [self.zegoApi logoutRoom];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self startPlayLive];
}

#pragma mark - private methods

- (void)setupUI {
    self.navigationItem.title = @"媒体次要信息拉流";
    self.sideInfoTextView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
    self.sideInfoTextView.textColor = [UIColor whiteColor];
    self.sideInfoTextView.textContainerInset = UIEdgeInsetsMake(-8, 0, 0, 0);
    self.sideInfoTextView.text = nil;
}

- (void)setupMediaSideInfoController {
    _mediaSideInfoController = [[ZGMediaSideInfoDemo alloc] init];
    _mediaSideInfoController.delegate = self;
}

- (void)startPlayLive {
    ZGAppGlobalConfig *appConfig = [[ZGAppGlobalConfigManager sharedInstance] globalConfig];
    
    // 设置 SDK 环境，需要在 init SDK 之前设置，后面调用 SDK 的 api 才能在该环境内执行
    [ZegoLiveRoomApi setUseTestEnv:(appConfig.environment == ZGAppEnvironmentTest)];
    
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
        // 设置媒体次要信息接收 controller, 才能在拉流时收到次要信息
        [self setupMediaSideInfoController];
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
        [self.zegoApi startPlayingStream:streamID inView:self.playLiveView];
        [self.zegoApi setViewMode:ZegoVideoViewModeScaleAspectFill ofStream:streamID];
        [self.zegoApi activateAudioPlayStream:streamID active:YES];
        [self.zegoApi activateVideoPlayStream:streamID active:YES];
    }
}

- (void)appendSideInfoMessageAndMakeVisible:(NSString *)sideInfoMessage {
    if (!sideInfoMessage || sideInfoMessage.length == 0) {
        return;
    }
    
    NSString *oldText = self.sideInfoTextView.text;
    NSString *newText = [NSString stringWithFormat:@"%@\n%@", oldText, sideInfoMessage];
    
    self.sideInfoTextView.text = newText;
    if(newText.length > 0 ) {
        UITextView *textView = self.sideInfoTextView;
        NSRange bottom = NSMakeRange(newText.length -1, 1);
        [textView scrollRangeToVisible:bottom];
        //        NSRange range = NSMakeRange(textView.text.length, 0);
        //        [textView scrollRangeToVisible:range];
        // an iOS bug, see https://stackoverflow.com/a/20989956/971070
        [textView setScrollEnabled:NO];
        [textView setScrollEnabled:YES];
    }
}

#pragma mark - ZegoLivePlayerDelegate

- (void)onPlayStateUpdate:(int)stateCode streamID:(NSString *)streamID {
    // 播放流状态回调
    if (stateCode == 0) {
        ZGLogInfo(@"拉流成功，streamID:%@", streamID);
    } else {
        ZGLogWarn(@"拉流失败，streamID:%@，stateCode:%d", streamID, stateCode);
    }
}

- (void)onPlayQualityUpdate:(int)quality stream:(NSString *)streamID videoFPS:(double)fps videoBitrate:(double)kbs {
    // 观看质量更新
}

#pragma mark - ZGMediaSideInfoDemoDelegate 

- (void)onReceiveMediaSideInfo:(NSData*)data ofStream:(NSString*)streamID {
    NSLog(@"%s", __func__);
    // 收到媒体次要信息
    if (!data) { return; }
    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!message) { return; }
    
    ZGLogInfo(@"收到媒体次要信息，message:%@", message);
    [self appendSideInfoMessageAndMakeVisible:message];
}

@end
#endif
