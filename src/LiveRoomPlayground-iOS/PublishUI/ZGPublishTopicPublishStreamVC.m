//
//  ZGPublishTopicPublishStreamVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/7.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_Publish

#import "ZGPublishTopicPublishStreamVC.h"
#import "ZGAppGlobalConfigManager.h"
#import "ZGAppSignHelper.h"
#import "ZegoHudManager.h"
#import "ZGTopicCommonDefines.h"
#import "ZGUserIDHelper.h"
#import "ZGPublishTopicConfigManager.h"
#import "ZGPublishTopicSettingVC.h"
#import <ZegoLiveRoom/ZegoLiveRoomApi.h>
#import <ZegoLiveRoom/zego-api-camera-oc.h>


#define PUBLISH_TOPIC_PUBLISH_FLAG_JOIN 0

NSString* const ZGPublishTopicPublishStreamVCKey_roomID = @"kRoomID";
NSString* const ZGPublishTopicPublishStreamVCKey_streamID = @"kStreamID";

@interface ZGPublishTopicPublishStreamVC () <ZegoRoomDelegate, ZegoLivePublisherDelegate, ZGPublishTopicConfigChangedHandler>

@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (weak, nonatomic) IBOutlet UITextView *processTipTextView;
@property (weak, nonatomic) IBOutlet UIStackView *startPublishStackView;
@property (weak, nonatomic) IBOutlet UITextField *roomIDTextField;
@property (weak, nonatomic) IBOutlet UITextField *streamIDTextField;
@property (weak, nonatomic) IBOutlet UIButton *startLiveButn;
@property (weak, nonatomic) IBOutlet UIButton *stopLiveButn;

@property (nonatomic) ZegoAVConfig *avConfig;
@property (nonatomic) ZegoVideoViewMode previewViewMode;
@property (nonatomic) BOOL enableHardwareEncode;
@property (nonatomic) ZegoVideoMirrorMode videoMirrorMode;
@property (nonatomic) BOOL enableMic;
@property (nonatomic) BOOL enableCamera;
@property (nonatomic) BOOL openAudioModule;
@property (nonatomic) BOOL useFrontCamera;
@property (nonatomic) BOOL isFocusLocked;

@property (nonatomic) ZegoLiveRoomApi *zegoApi;
@property (nonatomic) ZGTopicLoginRoomState loginRoomState;
@property (nonatomic) ZGTopicPublishStreamState publishStreamState;

@end

@implementation ZGPublishTopicPublishStreamVC

+ (instancetype)instanceFromStoryboard {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"PublishStream" bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:NSStringFromClass([ZGPublishTopicPublishStreamVC class])];
}

- (void)dealloc {
    NSLog(@"%@ dealloc.", [self class]);
    [self.zegoApi stopPreview];
    [self.zegoApi stopPublishing];
    [self.zegoApi logoutRoom];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[ZGPublishTopicConfigManager sharedInstance] addConfigChangedHandler:self];
    
    [self initializeTopicConfigs];
    [self setupUI];
    [self initializeZegoApi];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
    
    // 推流时，点击屏幕设置对焦点和曝光点
    if (_publishStreamState == ZGTopicPublishStreamStatePublishing) {
        [self unlockFocusAndExposure];
        CGPoint point = [[touches anyObject] locationInView:self.previewView];
        [self setFocusAndExposurePointInPreviewView:point];
    }
}

- (IBAction)startLiveButnClick:(id)sender {
    [self startLive];
}

- (IBAction)stopLiveButnClick:(id)sender {
    [self stopLive];
}

- (IBAction)enableMicValueChanged:(UISwitch*)sender {
    self.enableMic = sender.isOn;
    [self.zegoApi enableMic:self.enableMic];
}

- (IBAction)enableCameraValueChanged:(UISwitch*)sender {
    self.enableCamera = sender.isOn;
    [self.zegoApi enableCamera:self.enableCamera];
}

- (IBAction)openAudioModuleValueChanged:(UISwitch*)sender {
    self.openAudioModule = sender.isOn;
    if (self.openAudioModule) {
        [self.zegoApi resumeModule:ZEGOAPI_MODULE_AUDIO];
    } else {
        [self.zegoApi pauseModule:ZEGOAPI_MODULE_AUDIO];
    }
}

- (IBAction)switchFrontCameraValueChanged:(UISwitch *)sender {
    self.useFrontCamera = sender.isOn;
    [self.zegoApi setFrontCam:self.useFrontCamera];
}

#pragma mark - private methods

- (void)setupUI {
    self.navigationItem.title = @"推流";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"常用功能" style:UIBarButtonItemStylePlain target:self action:@selector(goConfigPage:)];
    
    self.processTipTextView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
    self.processTipTextView.textColor = [UIColor whiteColor];
    self.processTipTextView.textContainerInset = UIEdgeInsetsMake(-8, 0, 0, 0);
    
    self.stopLiveButn.alpha = 0;
    self.startPublishStackView.alpha = 1;
    
    // 加载持久化的 roomID, streamID
    self.roomIDTextField.text = [self savedValueForKey:ZGPublishTopicPublishStreamVCKey_roomID];
    self.streamIDTextField.text = [self savedValueForKey:ZGPublishTopicPublishStreamVCKey_streamID];

    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPresses:)];
    longPressGesture.minimumPressDuration = 1;
    [self.previewView addGestureRecognizer:longPressGesture];
}

- (void)longPresses:(UILongPressGestureRecognizer *)sender {
    // 推流时，长按屏幕锁定对焦点和曝光点
    if (_publishStreamState == ZGTopicPublishStreamStatePublishing && sender.state == UIGestureRecognizerStateBegan) {
        [self lockFocusAndExposure];
    }
}

- (void)goConfigPage:(id)sender {
    ZGPublishTopicSettingVC *vc = [ZGPublishTopicSettingVC instanceFromStoryboard];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)initializeTopicConfigs {
    ZegoAVConfig *avConfig = [[ZegoAVConfig alloc] init];
    CGSize resolution = [ZGPublishTopicConfigManager sharedInstance].resolution;
        avConfig.videoCaptureResolution = resolution;
    avConfig.videoEncodeResolution = resolution;
    avConfig.fps = (int)[ZGPublishTopicConfigManager sharedInstance].fps;
    avConfig.bitrate = (int)[ZGPublishTopicConfigManager sharedInstance].bitrate;
    self.avConfig = avConfig;
    
    self.previewViewMode = [ZGPublishTopicConfigManager sharedInstance].previewViewMode;
    
    self.enableHardwareEncode = [ZGPublishTopicConfigManager sharedInstance].isEnableHardwareEncode;
    
    self.videoMirrorMode = [ZGPublishTopicConfigManager sharedInstance].isPreviewMinnor ? ZegoVideoMirrorModePreviewMirrorPublishNoMirror : ZegoVideoMirrorModePreviewCaptureBothNoMirror;
    
    self.enableMic = YES;
    self.enableCamera = YES;
    self.openAudioModule = YES;
    self.useFrontCamera = YES;
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
        if (errorCode != 0) {
            ZGLogWarn(@"初始化失败,errorCode:%d", errorCode);
        }
        
        // 设置 api 的配置
        [self.zegoApi setAVConfig:self.avConfig];
        [self.zegoApi setPreviewViewMode:self.previewViewMode];
        [ZegoLiveRoomApi requireHardwareEncoder:self.enableHardwareEncode];
        [self.zegoApi setVideoMirrorMode:self.videoMirrorMode];
        
        [self.zegoApi enableMic:self.enableMic];
        [self.zegoApi enableCamera:self.enableCamera];
        [self.zegoApi setFrontCam:self.useFrontCamera];
        if (self.openAudioModule) {
            [self.zegoApi resumeModule:ZEGOAPI_MODULE_AUDIO];
        } else {
            [self.zegoApi pauseModule:ZEGOAPI_MODULE_AUDIO];
        }
        
        
        // 开始预览
        [self startPreview];
    }];
    if (!self.zegoApi) {
        [ZegoHudManager hideNetworkLoading];
        [self appendProcessTipAndMakeVisible:@"初始化失败"];
    } else {
        // 设置 SDK 相关代理
        [self.zegoApi setRoomDelegate:self];
        [self.zegoApi setPublisherDelegate:self];
    }
}

- (void)startPreview {
    [self.zegoApi setPreviewView:self.previewView];
    [self.zegoApi startPreview];
}

- (void)stopPreview {
    [self.zegoApi stopPreview];
    [self.zegoApi setPreviewView:nil];
}

- (void)startLive {
    if (self.loginRoomState != ZGTopicLoginRoomStateNotLogin) {
        ZGLogWarn(@"已登录或正在登录中，无需重复开始直播请求。");
        return;
    }
    if (self.publishStreamState != ZGTopicPublishStreamStateStopped) {
        ZGLogWarn(@"正在推流或正在请求推流中，无需重复开始直播请求。");
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
            ZGLogWarn(@"登录房间失败,roomID:%@,errorCode:%d", roomID, errorCode);
            [self appendProcessTipAndMakeVisible:[NSString stringWithFormat:@"登录房间失败,errorCode:%d", errorCode]];
            self.loginRoomState = ZGTopicLoginRoomStateNotLogin;
            [self invalidateLiveStateUILayout];
            // 登录房间失败
            [ZegoHudManager showMessage:[NSString stringWithFormat:@"登录房间失败,errorCode:%d", errorCode]];
            return;
        }
        ZGLogInfo(@"登录房间成功,roomID:%@", roomID);
        
        // 登录房间成功
        // 开始推流，在 ZegoLivePublisherDelegate 的 onPublishStateUpdate:streamID:streamInfo: 中或知推流结果
        [self saveValue:roomID forKey:ZGPublishTopicPublishStreamVCKey_roomID];
        [self saveValue:streamID forKey:ZGPublishTopicPublishStreamVCKey_streamID];
        [self appendProcessTipAndMakeVisible:@"登录房间成功"];
        self.loginRoomState = ZGTopicLoginRoomStateLogined;
        ZGLogInfo(@"请求推流,roomID:%@, stremID:%@", roomID, streamID);
        int publishFlag = ZEGO_SINGLE_ANCHOR;
#if PUBLISH_TOPIC_PUBLISH_FLAG_JOIN
        publishFlag = ZEGO_JOIN_PUBLISH;
#endif
        if ([self.zegoApi startPublishing:streamID title:nil flag:publishFlag]) {
            [self appendProcessTipAndMakeVisible:@"请求推流"];
            self.publishStreamState = ZGTopicPublishStreamStatePublishRequesting;
        } else {
            ZGLogWarn(@"请求推流失败。方法返回 NO");
        }
        [self invalidateLiveStateUILayout];
    }];
    if (reqResult) {
        [self appendProcessTipAndMakeVisible:@"请求登录房间"];
        self.loginRoomState = ZGTopicLoginRoomStateLoginRequesting;
        [self invalidateLiveStateUILayout];
    }
}

- (void)stopLive {
    if (self.loginRoomState != ZGTopicLoginRoomStateLogined) {
        NSLog(@"未登录，无需停止直播。");
        return;
    }
    if (self.publishStreamState != ZGTopicPublishStreamStatePublishing) {
        NSLog(@"不在进行推流，无需停止直播。");
        return;
    }
    
    [self clearProcessTips];
    [self internalStopLive];
}

- (void)internalStopLive {
    // 停止推流
    [self.zegoApi stopPublishing];
    [self appendProcessTipAndMakeVisible:@"停止推流"];
    // 登出房间
    [self.zegoApi logoutRoom];
    [self appendProcessTipAndMakeVisible:@"退出房间"];
    
    self.publishStreamState = ZGTopicPublishStreamStateStopped;
    self.loginRoomState = ZGTopicLoginRoomStateNotLogin;
    [self invalidateLiveStateUILayout];
    
    // 退出房间后，SDK 内部会停止预览。此时需要重新开启预览
    [self startPreview];
}

- (void)setFocusAndExposurePointInPreviewView:(CGPoint)point {
    CGPoint relativePoint = CGPointMake(point.x / self.previewView.bounds.size.width, point.y / self.previewView.bounds.size.height);
    [ZegoCamera setCamFocusPointInPreview:relativePoint channelIndex:ZEGOAPI_CHN_MAIN];
    [ZegoCamera setCamExposurePointInPreview:relativePoint channelIndex:ZEGOAPI_CHN_MAIN];
}

- (void)lockFocusAndExposure {
    ZGLogInfo(@"📷🔒 Lock focus and exposure");
    self.isFocusLocked = YES;
    [ZegoCamera setCamFocusMode:ZegoCameraFocusModeLocked channelIndex:ZEGOAPI_CHN_MAIN];
    [ZegoCamera setCamExposureMode:ZegoCameraExposureModeLocked channelIndex:ZEGOAPI_CHN_MAIN];
}

- (void)unlockFocusAndExposure {
    if (!self.isFocusLocked) {
        return;
    }
    ZGLogInfo(@"📷🔑 Unlock focus and exposure");
    self.isFocusLocked = NO;
    [ZegoCamera setCamFocusMode:ZegoCameraFocusModeContinuousAutoFocus channelIndex:ZEGOAPI_CHN_MAIN];
    [ZegoCamera setCamExposureMode:ZegoCameraExposureModeContinuousAutoExposure channelIndex:ZEGOAPI_CHN_MAIN];
}

- (void)invalidateLiveStateUILayout {
    if (self.loginRoomState == ZGTopicLoginRoomStateLogined &&
        self.publishStreamState == ZGTopicPublishStreamStatePublishing) {
        [self showLiveStartedStateUI];
    } else if (self.loginRoomState == ZGTopicLoginRoomStateNotLogin &&
        self.publishStreamState == ZGTopicPublishStreamStateStopped) {
        [self showLiveStoppedStateUI];
    } else {
        [self showLiveRequestingStateUI];
    }
}

- (void)showLiveRequestingStateUI {
    [self.startLiveButn setEnabled:NO];
    [self.stopLiveButn setEnabled:NO];
}

- (void)showLiveStartedStateUI {
    [self.startLiveButn setEnabled:NO];
    [self.stopLiveButn setEnabled:YES];
    [UIView animateWithDuration:0.5 animations:^{
        self.startPublishStackView.alpha = 0;
        self.stopLiveButn.alpha = 1;
    }];
}

- (void)showLiveStoppedStateUI {
    [self.startLiveButn setEnabled:YES];
    [self.stopLiveButn setEnabled:NO];
    [UIView animateWithDuration:0.5 animations:^{
        self.startPublishStackView.alpha = 1;
        self.stopLiveButn.alpha = 0;
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
    ZGLogWarn(@"onKickOut，reason:%d, roomID:%@", reason, roomID);
    NSLog(@"onKickOut, reason:%d", reason);
    [self appendProcessTipAndMakeVisible:[NSString stringWithFormat:@"被踢出房间, reason:%d", reason]];
    [self internalStopLive];
}

- (void)onDisconnect:(int)errorCode roomID:(NSString *)roomID {
    ZGLogWarn(@"onDisconnect，errorCode:%d, roomID:%@", errorCode, roomID);
    NSLog(@"onDisconnect, errorCode:%d", errorCode);
    [self appendProcessTipAndMakeVisible:[NSString stringWithFormat:@"已断开和房间的连接, errorCode:%d", errorCode]];
    [self internalStopLive];
}

- (void)onReconnect:(int)errorCode roomID:(NSString *)roomID {
    ZGLogWarn(@"onReconnect，errorCode:%d, roomID:%@", errorCode, roomID);
    NSLog(@"onReconnect, errorCode:%d", errorCode);
    [self appendProcessTipAndMakeVisible:[NSString stringWithFormat:@"重连, errorCode:%d", errorCode]];
}

- (void)onTempBroken:(int)errorCode roomID:(NSString *)roomID {
    ZGLogWarn(@"onTempBroken，errorCode:%d", errorCode);
    NSLog(@"onTempBroken, errorCode:%d", errorCode);
    [self appendProcessTipAndMakeVisible:[NSString stringWithFormat:@"暂时断开, errorCode:%d", errorCode]];
}

#pragma mark - ZegoLivePublisherDelegate

- (void)onPublishStateUpdate:(int)stateCode streamID:(NSString *)streamID streamInfo:(NSDictionary *)info {
    // stateCode == 0 表示推流成功
    self.publishStreamState = stateCode == 0 ? ZGTopicPublishStreamStatePublishing:ZGTopicPublishStreamStateStopped;
    [self invalidateLiveStateUILayout];
    
    if (stateCode == 0) {
        ZGLogInfo(@"推流请求成功, streamID:%@", streamID);
        [self appendProcessTipAndMakeVisible:@"推流请求成功，正在推流"];
    } else {
        ZGLogWarn(@"推流请求失败，streamID:%@，stateCode:%d", streamID, stateCode);
        [self appendProcessTipAndMakeVisible:[NSString stringWithFormat:@"推流请求失败，stateCode:%d",stateCode]];
    }
}

#pragma mark - ZGPublishTopicConfigChangedHandler

- (void)publishTopicConfigManager:(ZGPublishTopicConfigManager *)configManager resolutionDidChange:(CGSize)resolution {
    ZegoAVConfig *avConfig = self.avConfig;
    if (!avConfig) {
        return;
    }
    avConfig.videoEncodeResolution = resolution;
    avConfig.videoCaptureResolution = resolution;
    
    [self.zegoApi setAVConfig:avConfig];
}

- (void)publishTopicConfigManager:(ZGPublishTopicConfigManager *)configManager fpsDidChange:(NSInteger)fps {
    ZegoAVConfig *avConfig = self.avConfig;
    if (!avConfig) {
        return;
    }
    avConfig.fps = (int)fps;
    
    [self.zegoApi setAVConfig:avConfig];
}

- (void)publishTopicConfigManager:(ZGPublishTopicConfigManager *)configManager bitrateDidChange:(NSInteger)bitrate {
    ZegoAVConfig *avConfig = self.avConfig;
    if (!avConfig) {
        return;
    }
    avConfig.bitrate = (int)bitrate;
    
    [self.zegoApi setAVConfig:avConfig];
}

- (void)publishTopicConfigManager:(ZGPublishTopicConfigManager *)configManager previewViewModeDidChange:(ZegoVideoViewMode)previewViewMode {
    self.previewViewMode = previewViewMode;
    [self.zegoApi setPreviewViewMode:previewViewMode];
}

- (void)publishTopicConfigManager:(ZGPublishTopicConfigManager *)configManager enableHardwareEncodeDidChange:(BOOL)enableHardwareEncode {
    self.enableHardwareEncode = enableHardwareEncode;
    [ZegoLiveRoomApi requireHardwareEncoder:enableHardwareEncode];
}

- (void)publishTopicConfigManager:(ZGPublishTopicConfigManager *)configManager previewMinnorDidChange:(BOOL)isPreviewMinnor {
    self.videoMirrorMode = isPreviewMinnor ?  ZegoVideoMirrorModePreviewMirrorPublishNoMirror : ZegoVideoMirrorModePreviewCaptureBothNoMirror;
    [self.zegoApi setVideoMirrorMode:self.videoMirrorMode];
}

@end

#endif
