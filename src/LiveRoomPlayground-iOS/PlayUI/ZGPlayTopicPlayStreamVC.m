//
//  ZGPlayTopicPlayStreamVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/9.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_Play

#import "ZGPlayTopicPlayStreamVC.h"
#import "ZGAppGlobalConfigManager.h"
#import "ZGPlayTopicConfigManager.h"
#import "ZGAppSignHelper.h"
#import "ZGUserIDHelper.h"
#import "ZGTopicCommonDefines.h"
#import "ZGPlayTopicSettingVC.h"
#import <ZegoLiveRoom/ZegoLiveRoomApi.h>
#import <ZegoLiveRoom/ZegoLiveRoomApi-Player.h>

// 是否判断目标流在当前登录房间中
#define ZG_PLAY_STREAM_TOPIC_JUDGE_TARGET_PLAY_STREAM_IN_ROOM 0

NSString* const ZGPlayTopicPlayStreamVCKey_roomID = @"kRoomID";
NSString* const ZGPlayTopicPlayStreamVCKey_streamID = @"kStreamID";

@interface ZGPlayTopicPlayStreamVC () <ZegoRoomDelegate, ZegoLivePlayerDelegate, ZGPlayTopicConfigChangedHandler>

@property (weak, nonatomic) IBOutlet UIView *playLiveView;
@property (weak, nonatomic) IBOutlet UITextView *processTipTextView;
@property (weak, nonatomic) IBOutlet UILabel *playLiveQualityLabel;
@property (weak, nonatomic) IBOutlet UIView *startPlayLiveStackView;
@property (weak, nonatomic) IBOutlet UITextField *roomIDTextField;
@property (weak, nonatomic) IBOutlet UITextField *streamIDTextField;
@property (weak, nonatomic) IBOutlet UIButton *startPlayLiveButn;
@property (weak, nonatomic) IBOutlet UIButton *stopPlayLiveButn;

@property (nonatomic) ZegoVideoViewMode playViewMode;
@property (nonatomic) BOOL enableHardwareDecode;
@property (nonatomic) int playStreamVolume;
@property (nonatomic) ZegoVideoMirrorMode openPreviewMirror;

@property (nonatomic) ZegoLiveRoomApi *zegoApi;
@property (nonatomic) ZGTopicLoginRoomState loginRoomState;
@property (nonatomic) BOOL isPlayingLive;

// 当前在播放的流 ID
@property (nonatomic, copy) NSString *currentStreamID;

@end

@implementation ZGPlayTopicPlayStreamVC

+ (instancetype)instanceFromStoryboard {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"PlayStream" bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:NSStringFromClass([ZGPlayTopicPlayStreamVC class])];
}

- (void)dealloc {
    NSLog(@"%@ dealloc.", [self class]);
    [self.zegoApi stopPreview];
    [self.zegoApi stopPublishing];
    [self.zegoApi logoutRoom];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[ZGPlayTopicConfigManager sharedInstance] addConfigChangedHandler:self];
    [self initializeTopicConfigs];
    [self setupUI];
    [self initializeZegoApi];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (IBAction)startPlayLiveButnClick:(id)sender {
    [self startPlayLive];
}

- (IBAction)stopStopLiveButnClick:(id)sender {
    [self stopPlayLive];
}


#pragma mark - private methods

- (void)setupUI {
    self.navigationItem.title = @"拉流";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"常用功能" style:UIBarButtonItemStylePlain target:self action:@selector(goConfigPage:)];

    self.processTipTextView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
    self.processTipTextView.textColor = [UIColor whiteColor];
    self.processTipTextView.textContainerInset = UIEdgeInsetsMake(-8, 0, 0, 0);
    
    self.playLiveQualityLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
    self.playLiveQualityLabel.textColor = [UIColor whiteColor];
    self.playLiveQualityLabel.text = @"";

    self.stopPlayLiveButn.alpha = 0;
    self.startPlayLiveStackView.alpha = 1;

    // 加载持久化的 roomID, streamID
    self.roomIDTextField.text = [self savedValueForKey:ZGPlayTopicPlayStreamVCKey_roomID];
    self.streamIDTextField.text = [self savedValueForKey:ZGPlayTopicPlayStreamVCKey_streamID];
}

- (void)goConfigPage:(id)sender {
    ZGPlayTopicSettingVC *vc = [ZGPlayTopicSettingVC instanceFromStoryboard];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)initializeTopicConfigs {
    self.playViewMode = [ZGPlayTopicConfigManager sharedInstance].playViewMode;
    self.enableHardwareDecode = [ZGPlayTopicConfigManager sharedInstance].isEnableHardwareDecode;
    self.playStreamVolume = [ZGPlayTopicConfigManager sharedInstance].playStreamVolume;
    self.openPreviewMirror = [ZGPlayTopicConfigManager sharedInstance].isPreviewMinnor;
}

- (void)initializeZegoApi {
    ZGAppGlobalConfig *appConfig = [[ZGAppGlobalConfigManager sharedInstance] globalConfig];
    
    // 设置 SDK 环境，需要在 init SDK 之前设置，后面调用 SDK 的 api 才能在该环境内执行
    [ZegoLiveRoomApi setUseTestEnv:(appConfig.environment == ZGAppEnvironmentTest)];
    
    // init SDK
    [self appendProcessTipAndMakeVisible:@"请求初始化"];
    [ZegoHudManager showNetworkLoading];
    Weakify(self);
    self.zegoApi = [[ZegoLiveRoomApi alloc] initWithAppID:(unsigned int)appConfig.appID appSignature:[ZGAppSignHelper convertAppSignFromString:appConfig.appSign] completionBlock:^(int errorCode) {
        Strongify(self);
        [ZegoHudManager hideNetworkLoading];
        [self appendProcessTipAndMakeVisible:errorCode == 0?@"初始化完成":[NSString stringWithFormat:@"初始化失败，errorCode:%d",errorCode]];
        if(errorCode != 0) {
            ZGLogWarn(@"初始化失败，errorCode:%d",errorCode);
        }
    }];
    if (!self.zegoApi) {
        [ZegoHudManager hideNetworkLoading];
        [self appendProcessTipAndMakeVisible:@"初始化失败"];
    } else {
        // 设置 SDK 相关代理
        [self.zegoApi setRoomDelegate:self];
        [self.zegoApi setPlayerDelegate:self];
    }
    [self.zegoApi setVideoMirrorMode:self.openPreviewMirror?ZegoVideoMirrorModePreviewMirrorPublishNoMirror:ZegoVideoMirrorModePreviewCaptureBothNoMirror];

}

- (void)startPlayLive {
    if (self.loginRoomState != ZGTopicLoginRoomStateNotLogin) {
        NSLog(@"已登录或正在登录中，无需重复进入直播请求。");
        return;
    }
    if (self.isPlayingLive) {
        NSLog(@"已进入直播中，无需重复进入直播请求。");
        return;
    }
    
    // 获取 userID，userName 并设置到 SDK 中。必须在 loginRoom 之前设置，否则会出现登录不进行回调的问题
    // 这里演示简单将时间戳作为 userID，将 userID 和 userName 设置成一样。实际使用中可以根据需要，设置成业务相关的 userID
    NSString *userID = ZGUserIDHelper.userID;
    [ZegoLiveRoomApi setUserID:userID userName:userID];
    
    
    // 登录房间
    NSString *roomID = self.roomIDTextField.text;
    NSString *streamID = self.streamIDTextField.text;
    if (![self checkParamNotEmpty:@"roomID" paramValue:roomID] ||
        ![self checkParamNotEmpty:@"streamID" paramValue:streamID]) {
        return;
    }
    
    Weakify(self);
    [ZegoHudManager showNetworkLoading];
    BOOL reqResult = [_zegoApi loginRoom:roomID role:ZEGO_ANCHOR withCompletionBlock:^(int errorCode, NSArray<ZegoStream *> *streamList) {
        Strongify(self);
        [ZegoHudManager hideNetworkLoading];
        
        if (errorCode != 0) {
            ZGLogWarn(@"登录房间失败，errorCode:%d",errorCode);
            [self appendProcessTipAndMakeVisible:[NSString stringWithFormat:@"登录房间失败,errorCode:%d", errorCode]];
            self.loginRoomState = ZGTopicLoginRoomStateNotLogin;
            [self invalidatePlayLiveStateUILayout];
            // 登录房间失败
            [ZegoHudManager showMessage:[NSString stringWithFormat:@"登录房间失败,errorCode:%d", errorCode]];
            return;
        }
        
        // 登录房间成功
        self.loginRoomState = ZGTopicLoginRoomStateLogined;
        [self appendProcessTipAndMakeVisible:@"登录房间成功"];
        
        [self saveValue:roomID forKey:ZGPlayTopicPlayStreamVCKey_roomID];
        [self saveValue:streamID forKey:ZGPlayTopicPlayStreamVCKey_streamID];
        
        // 如果存在目标流则播放，如果不存在则日志记录不存在目标流
        BOOL needPlayStream = YES;
        BOOL needHandleStreamNotExist = NO;
#if ZG_PLAY_STREAM_TOPIC_JUDGE_TARGET_PLAY_STREAM_IN_ROOM
        NSArray<NSString *> *roomStreamIDs = [streamList valueForKeyPath:@"streamID"];
        if (![roomStreamIDs containsObject:streamID]) {
            needPlayStream = NO;
            needHandleStreamNotExist = YES;
        }
#endif
        if (needPlayStream) {
            // play stream
            self.isPlayingLive = YES;
            self.currentStreamID = streamID;
            [self invalidatePlayLiveStateUILayout];
            
            // 根据配置设置 ZegoLiveRoomApi
            [ZegoLiveRoomApi requireHardwareDecoder:self.enableHardwareDecode];
            
            // 开始拉流
            [self.zegoApi startPlayingStream:streamID inView:self.playLiveView];
            [self.zegoApi enableViewMirror:self.openPreviewMirror ofStream:self.currentStreamID];
            
            // 根据拉流配置设置拉流
            [self.zegoApi setPlayVolume:self.playStreamVolume ofStream:streamID];
            [self.zegoApi setViewMode:self.playViewMode ofStream:streamID];
            
            [self appendProcessTipAndMakeVisible:@"正在拉流"];
        }
        
        if (needHandleStreamNotExist) {
            [self appendProcessTipAndMakeVisible:@"房间不存在目标流"];
            [self appendProcessTipAndMakeVisible:@"退出房间"];
            [self.zegoApi logoutRoom];
            self.loginRoomState = ZGTopicLoginRoomStateNotLogin;
            [self invalidatePlayLiveStateUILayout];
            [ZegoHudManager showMessage:@"房间不存在目标流"];
        }
    }];
    if (reqResult) {
        [self appendProcessTipAndMakeVisible:@"请求登录房间"];
        self.loginRoomState = ZGTopicLoginRoomStateLoginRequesting;
        [self invalidatePlayLiveStateUILayout];
    }
}

- (void)stopPlayLive {
    if (self.loginRoomState != ZGTopicLoginRoomStateLogined) {
        NSLog(@"未登录，无需退出直播。");
        return;
    }
    if (!self.isPlayingLive) {
        NSLog(@"未进入直播，无需退出直播。");
        return;
    }
    
    [self clearProcessTips];
    [self internalStopPlayLive];
}

- (void)internalStopPlayLive {
    NSString *currentStreamID = self.currentStreamID;
    if (currentStreamID) {
        // 停止拉流
        [self.zegoApi stopPlayingStream:self.currentStreamID];
        [self appendProcessTipAndMakeVisible:@"停止拉流"];
        // 登出房间
        [self.zegoApi logoutRoom];
        [self appendProcessTipAndMakeVisible:@"退出房间"];
        
        self.isPlayingLive = NO;
        self.loginRoomState = ZGTopicLoginRoomStateNotLogin;
        [self invalidatePlayLiveStateUILayout];
        
        self.currentStreamID = nil;
        self.playLiveQualityLabel.text = @"";
    }
}

- (void)invalidatePlayLiveStateUILayout {
    if (self.loginRoomState == ZGTopicLoginRoomStateLogined &&
        self.isPlayingLive) {
        [self showPlayLiveStartedStateUI];
    } else if (self.loginRoomState == ZGTopicLoginRoomStateNotLogin &&
               !self.isPlayingLive) {
        [self showPlayLiveStoppedStateUI];
    } else {
        [self showPlayLiveRequestingStateUI];
    }
}

- (void)showPlayLiveRequestingStateUI {
    [self.startPlayLiveButn setEnabled:NO];
    [self.stopPlayLiveButn setEnabled:NO];
}

- (void)showPlayLiveStartedStateUI {
    [self.startPlayLiveButn setEnabled:NO];
    [self.stopPlayLiveButn setEnabled:YES];
    [UIView animateWithDuration:0.5 animations:^{
        self.startPlayLiveStackView.alpha = 0;
        self.stopPlayLiveButn.alpha = 1;
    }];
}

- (void)showPlayLiveStoppedStateUI {
    [self.startPlayLiveButn setEnabled:YES];
    [self.stopPlayLiveButn setEnabled:NO];
    [UIView animateWithDuration:0.5 animations:^{
        self.startPlayLiveStackView.alpha = 1;
        self.stopPlayLiveButn.alpha = 0;
    }];
}

- (void)appendProcessTipAndMakeVisible:(NSString *)tipText {
    if (!tipText || tipText.length == 0) {
        return;
    }
    
    NSString *oldText = self.processTipTextView.text;
    NSString *newText = [NSString stringWithFormat:@"%@\n%@", oldText, tipText];
    
    self.processTipTextView.text = newText;
    if(newText.length > 0 ) {
        UITextView *textView = self.processTipTextView;
        NSRange bottom = NSMakeRange(newText.length -1, 1);
        [textView scrollRangeToVisible:bottom];
        //        NSRange range = NSMakeRange(textView.text.length, 0);
        //        [textView scrollRangeToVisible:range];
        // an iOS bug, see https://stackoverflow.com/a/20989956/971070
        [textView setScrollEnabled:NO];
        [textView setScrollEnabled:YES];
    }
}

- (void)clearProcessTips {
    self.processTipTextView.text = @"";
}

- (BOOL)checkParamNotEmpty:(NSString *)paramName paramValue:(id)paramValue {
    BOOL passCheck = paramValue != nil;
    if ([paramValue isKindOfClass:[NSString class]]) {
        passCheck = ((NSString *)paramValue).length != 0;
    }
    if (!passCheck) {
        NSLog(@"`%@` is empty or nil.", paramName);
    }
    return passCheck;
}

#pragma mark - ZegoRoomDelegate

- (void)onKickOut:(int)reason roomID:(NSString *)roomID {
    ZGLogWarn(@"onKickOut，reason:%d", reason);
    NSLog(@"onKickOut, reason:%d", reason);
    [self appendProcessTipAndMakeVisible:[NSString stringWithFormat:@"被踢出房间, reason:%d", reason]];
    [self internalStopPlayLive];
}

- (void)onDisconnect:(int)errorCode roomID:(NSString *)roomID {
    ZGLogWarn(@"onDisconnect, errorCode:%d", errorCode);
    NSLog(@"onDisconnect, errorCode:%d", errorCode);
    [self appendProcessTipAndMakeVisible:[NSString stringWithFormat:@"已断开和房间的连接, errorCode:%d", errorCode]];
    [self internalStopPlayLive];
}

- (void)onReconnect:(int)errorCode roomID:(NSString *)roomID {
    ZGLogWarn(@"onReconnect, errorCode:%d", errorCode);
    NSLog(@"onReconnect, errorCode:%d", errorCode);
    [self appendProcessTipAndMakeVisible:[NSString stringWithFormat:@"重连, errorCode:%d", errorCode]];
}

- (void)onTempBroken:(int)errorCode roomID:(NSString *)roomID {
    ZGLogWarn(@"onTempBroken, errorCode:%d", errorCode);
    NSLog(@"onTempBroken, errorCode:%d", errorCode);
    [self appendProcessTipAndMakeVisible:[NSString stringWithFormat:@"暂时断开, errorCode:%d", errorCode]];
}

- (void)onStreamUpdated:(int)type streams:(NSArray<ZegoStream*> *)streamList roomID:(NSString *)roomID {
    // 房间内流增减变化处理。
    
    // 如果删除列表中存在当前拉流，则停止当前拉流播放
    NSString *currentStreamID = self.currentStreamID;
    NSArray<NSString*> *streamIDs = [streamList valueForKeyPath:@"streamID"];
    if (type == ZEGO_STREAM_DELETE &&
        currentStreamID &&
        [streamIDs containsObject:currentStreamID]) {
        NSLog(@"收到当前拉流删除通知");
        ZGLogInfo(@"收到当前拉流删除通知");
        [self appendProcessTipAndMakeVisible:@"收到当前拉流删除通知"];
        [self internalStopPlayLive];
    }
}

#pragma mark - ZegoLivePlayerDelegate

- (void)onPlayStateUpdate:(int)stateCode streamID:(NSString *)streamID {
    // 拉流回调，stateCode == 0 表示拉流成功
    if ([streamID isEqualToString:self.currentStreamID] &&
        self.isPlayingLive) {
        if (stateCode == 0) {
            ZGLogWarn(@"拉流成功");
            [self appendProcessTipAndMakeVisible:@"拉流成功"];
        } else {
            ZGLogWarn(@"拉流失败，stateCode:%d", stateCode);
            [self appendProcessTipAndMakeVisible:[NSString stringWithFormat:@"拉流失败，stateCode:%d", stateCode]];
        }
    }
}

- (void)onPlayQualityUpate:(NSString *)streamID quality:(ZegoApiPlayQuality)quality {
    NSMutableString *text = [NSMutableString string];
    [text appendFormat:@"帧率：%d \n", (int)quality.vdecFps];
    [text appendFormat:@"码率:%.2f kb/s \n", quality.kbps];
    [text appendFormat:@"分辨率:%dx%d", quality.width, quality.height];
#ifdef DEBUG
    NSLog(@"拉流质量。fps:%d vdjFps:%d vdecFps:%d vrndFps:%d", (int)quality.fps, (int)quality.vdjFps, (int)quality.vdecFps, (int)quality.vrndFps);
#endif
    self.playLiveQualityLabel.text = [text copy];
}

/**
 远端摄像头状态通知
 */
- (void)onRemoteCameraStatusUpdate:(int)status ofStream:(NSString *)streamID {
    NSLog(@"onRemoteCameraStatusUpdate, status:%d", status);
    [self appendProcessTipAndMakeVisible:[NSString stringWithFormat:@"远端摄像头状态, status:%d", status]];
}

/**
 远端麦克风状态通知
 */
- (void)onRemoteMicStatusUpdate:(int)status ofStream:(NSString *)streamID {
    NSLog(@"onRemoteMicStatusUpdate, status:%d", status);
    [self appendProcessTipAndMakeVisible:[NSString stringWithFormat:@"远端mic状态, status:%d", status]];
}

#pragma mark - ZGPlayTopicConfigChangedHandler

- (void)playTopicConfigManager:(ZGPlayTopicConfigManager *)configManager playViewModeDidChange:(ZegoVideoViewMode)playViewMode {
    self.playViewMode = playViewMode;
    
    NSString *currentStreamID = self.currentStreamID;
    if (currentStreamID) {
        [self.zegoApi setViewMode:playViewMode ofStream:currentStreamID];
    }
}

- (void)playTopicConfigManager:(ZGPlayTopicConfigManager *)configManager playStreamVolumeDidChange:(int)playStreamVolume {
    self.playStreamVolume = playStreamVolume;
    
    NSString *currentStreamID = self.currentStreamID;
    if (currentStreamID) {
        [self.zegoApi setPlayVolume:playStreamVolume ofStream:currentStreamID];
    }
}

- (void)playTopicConfigManager:(ZGPlayTopicConfigManager *)configManager enableHardwareDecodeDidChange:(BOOL)enableHardwareDecode {
    self.enableHardwareDecode = enableHardwareDecode;
    [ZegoLiveRoomApi requireHardwareDecoder:enableHardwareDecode];
}

- (void)playTopicConfigManager:(ZGPlayTopicConfigManager *)configManager previewMinnorDidChange:(BOOL)isPreviewMinnor
{
    self.openPreviewMirror = isPreviewMinnor;
    [self.zegoApi enableViewMirror:isPreviewMinnor ofStream:self.currentStreamID];
}

@end

#endif
