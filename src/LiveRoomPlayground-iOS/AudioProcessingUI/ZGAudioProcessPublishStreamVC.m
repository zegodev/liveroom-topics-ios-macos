//
//  ZGAudioProcessPublishStreamVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/27.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_AudioProcessing

#import "ZGAudioProcessPublishStreamVC.h"
#import "ZGAudioProcessVoiceChangeConfigVC.h"
#import "ZGAudioProcessVirtualStereoConfigVC.h"
#import "ZGAudioProcessReverbConfigVC.h"
#import "ZGAppGlobalConfigManager.h"
#import "ZGAppSignHelper.h"
#import "ZGAudioProcessTopicConfigManager.h"
#import <ZegoLiveRoom/ZegoLiveRoom.h>
#import <ZegoLiveRoom/zego-api-audio-processing-oc.h>

@interface ZGAudioProcessPublishStreamVC () <ZegoRoomDelegate, ZegoLivePublisherDelegate, ZGAudioProcessTopicConfigChangedHandler>

@property (weak, nonatomic) IBOutlet UIView *previewView;

@property (nonatomic) ZegoLiveRoomApi *zegoApi;

@end

@implementation ZGAudioProcessPublishStreamVC

+ (instancetype)instanceFromStoryboard {
    return [[UIStoryboard storyboardWithName:@"AudioProcessing" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass([ZGAudioProcessPublishStreamVC class])];
}

- (void)dealloc {
    NSLog(@"%@ dealloc", [self class]);
    [_zegoApi stopPreview];
    [_zegoApi stopPublishing];
    [_zegoApi logoutRoom];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"音效处理-推流";
    
    [[ZGAudioProcessTopicConfigManager sharedInstance] addConfigChangedHandler:self];
    
    [self setupZegoComponents];
    [self startLive];
}

- (IBAction)voiceChangeConfigButnClick:(id)sender {
    ZGAudioProcessVoiceChangeConfigVC *vc = [ZGAudioProcessVoiceChangeConfigVC instanceFromStoryboard];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)virtualStereoConfigButnClick:(id)sender {
    ZGAudioProcessVirtualStereoConfigVC *vc = [ZGAudioProcessVirtualStereoConfigVC instanceFromStoryboard];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)reverbConfigButnClick:(id)sender {
    ZGAudioProcessReverbConfigVC *vc = [ZGAudioProcessReverbConfigVC instanceFromStoryboard];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - private methods

- (void)setupZegoComponents {
    ZGAppGlobalConfig *appConfig = [[ZGAppGlobalConfigManager sharedInstance] globalConfig];
    
    // 设置环境
    [ZegoLiveRoomApi setUseTestEnv:(appConfig.environment == ZGAppEnvironmentTest)];
    // 设置硬编硬解
    [ZegoLiveRoomApi requireHardwareEncoder:appConfig.openHardwareEncode];
    [ZegoLiveRoomApi requireHardwareDecoder:appConfig.openHardwareDecode];
    [ZegoLiveRoomApi setVideoCaptureFactory:nil];
    
    // setup zegoApi
    self.zegoApi = [[ZegoLiveRoomApi alloc] initWithAppID:appConfig.appID appSignature:[ZGAppSignHelper convertAppSignFromString:appConfig.appSign] completionBlock:^(int errorCode) {
        if (errorCode == 0) {
            ZGLogInfo(@"zego api 初始化成功");
        } else {
            ZGLogWarn(@"zego api 初始化失败，errorCode:%d", errorCode);
        }
    }];
    [self.zegoApi setRoomDelegate:self];
    [self.zegoApi setPublisherDelegate:self];
}

- (void)startLive {
    [self.zegoApi setPreviewView:self.previewView];
    [self.zegoApi startPreview];
    
    NSString *userID = ZGUserIDHelper.userID;
    [ZegoLiveRoomApi setUserID:userID userName:userID];
    
    NSString *roomID = self.roomID;
    NSString *streamID = self.streamID;
    Weakify(self);
    [_zegoApi loginRoom:roomID role:ZEGO_ANCHOR withCompletionBlock:^(int errorCode, NSArray<ZegoStream *> *streamList) {
        Strongify(self);
        if (errorCode != 0) {
            ZGLogWarn(@"登录房间失败，errorCode:%d", errorCode);
            return;
        }
        ZGLogInfo(@"登录房间成功");
        
        // 设置音效处理配置
        [self applyVoiceChangerConfig];
        [self applyVirtualStereoConfig];
        [self applyReverbConfig];
        // 开始推流
        ZGLogInfo(@"请求推流");
        [self.zegoApi startPublishing:streamID title:nil flag:ZEGO_SINGLE_ANCHOR];
    }];
}

- (void)applyVoiceChangerConfig {
    float voiceChangerParam = ZEGOAPI_VOICE_CHANGER_NONE;
    BOOL voiceChangerOpen = [ZGAudioProcessTopicConfigManager sharedInstance].voiceChangerOpen;
    if (voiceChangerOpen) {
        voiceChangerParam = [ZGAudioProcessTopicConfigManager sharedInstance].voiceChangerParam;
    }
    [ZegoAudioProcessing setVoiceChangerParam:voiceChangerParam];
}

- (void)applyVirtualStereoConfig {
    BOOL virtualStereoOpen = [ZGAudioProcessTopicConfigManager sharedInstance].virtualStereoOpen;
    if (virtualStereoOpen) {
        // 需开启双声道，虚拟立体声才能生效
        [_zegoApi setAudioChannelCount:2];
        int angle = [ZGAudioProcessTopicConfigManager sharedInstance].virtualStereoAngle;
        [ZegoAudioProcessing enableVirtualStereo:YES angle:angle];
    } else {
        [ZegoAudioProcessing enableVirtualStereo:NO angle:0];
    }
}

- (void)applyReverbConfig {
    BOOL reverbOpen = [ZGAudioProcessTopicConfigManager sharedInstance].reverbOpen;
    if (reverbOpen) {
        NSUInteger reverbMode = [ZGAudioProcessTopicConfigManager sharedInstance].reverbMode;
        if (reverbMode != NSNotFound) {
            [ZegoAudioProcessing enableReverb:YES mode:reverbMode];
        } else {
            float roomSize = [ZGAudioProcessTopicConfigManager sharedInstance].customReverbRoomSize;
            float reverberance = [ZGAudioProcessTopicConfigManager sharedInstance].customReverberance;
            float damping = [ZGAudioProcessTopicConfigManager sharedInstance].customDamping;
            float drWetRatio = [ZGAudioProcessTopicConfigManager sharedInstance].customDryWetRatio;
            ZegoAudioReverbParam reverbParam = {roomSize, reverberance, damping, drWetRatio};
            [ZegoAudioProcessing setReverbParam:reverbParam];
        }
    } else {
        [ZegoAudioProcessing enableReverb:NO mode:0];
        ZegoAudioReverbParam reverbParam = {0.f,0.f,0.f,0.f};
        [ZegoAudioProcessing setReverbParam:reverbParam];
    }
}

#pragma mark - ZegoRoomDelegate

- (void)onKickOut:(int)reason roomID:(NSString *)roomID {
    ZGLogWarn(@"%s, reason:%d", __func__, reason);
}

- (void)onDisconnect:(int)errorCode roomID:(NSString *)roomID {
    ZGLogWarn(@"%s, errorCode:%d", __func__, errorCode);
}

- (void)onReconnect:(int)errorCode roomID:(NSString *)roomID {
    ZGLogWarn(@"%s, errorCode:%d", __func__, errorCode);
}

#pragma mark - ZegoLivePublisherDelegate

- (void)onPublishStateUpdate:(int)stateCode streamID:(NSString *)streamID streamInfo:(NSDictionary *)info {
    if (stateCode == 0) {
        ZGLogInfo(@"推流成功");
    } else {
        ZGLogWarn(@"推流失败。stateCode:%d", stateCode);
    }
}

#pragma mark - ZGAudioProcessTopicConfigChangedHandler

- (void)audioProcessTopicConfigManager:(ZGAudioProcessTopicConfigManager *)configManager
               voiceChangerOpenChanged:(BOOL)voiceChangerOpen {
    [self applyVoiceChangerConfig];
}

- (void)audioProcessTopicConfigManager:(ZGAudioProcessTopicConfigManager *)configManager
              voiceChangerParamChanged:(float)voiceChangerParam {
    [self applyVoiceChangerConfig];
}

- (void)audioProcessTopicConfigManager:(ZGAudioProcessTopicConfigManager *)configManager
              virtualStereoOpenChanged:(BOOL)virtualStereoOpen {
    [self applyVirtualStereoConfig];
}

- (void)audioProcessTopicConfigManager:(ZGAudioProcessTopicConfigManager *)configManager
             virtualStereoAngleChanged:(int)virtualStereoAngle {
    [self applyVirtualStereoConfig];
}

- (void)audioProcessTopicConfigManager:(ZGAudioProcessTopicConfigManager *)configManager
                     reverbOpenChanged:(BOOL)reverbOpen {
    [self applyReverbConfig];
}

- (void)audioProcessTopicConfigManager:(ZGAudioProcessTopicConfigManager *)configManager
                     reverbModeChanged:(NSUInteger)reverbMode {
    [self applyReverbConfig];
}

- (void)audioProcessTopicConfigManager:(ZGAudioProcessTopicConfigManager *)configManager
           customReverbRoomSizeChanged:(float)customReverbRoomSize {
    [self applyReverbConfig];
}

- (void)audioProcessTopicConfigManager:(ZGAudioProcessTopicConfigManager *)configManager
              customDryWetRatioChanged:(float)customDryWetRatio {
    [self applyReverbConfig];
}

- (void)audioProcessTopicConfigManager:(ZGAudioProcessTopicConfigManager *)configManager
                  customDampingChanged:(float)customDamping {
    [self applyReverbConfig];
}

- (void)audioProcessTopicConfigManager:(ZGAudioProcessTopicConfigManager *)configManager
             customReverberanceChanged:(float)customReverberance {
    [self applyReverbConfig];
}

@end
#endif
