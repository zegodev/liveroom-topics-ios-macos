//
//  ZGAudioPlayerPublishStreamVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/23.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_AudioPlayer

#import "ZGAudioPlayerPublishStreamVC.h"
#import "ZGAppGlobalConfigManager.h"
#import "ZGAppSignHelper.h"
#import <ZegoLiveRoom/zego-api-audio-player-oc.h>

@interface ZGAudioPlayerPublishStreamVC () <ZegoRoomDelegate, ZegoLivePublisherDelegate, ZegoAudioPlayerDelegate>

@property (weak, nonatomic) IBOutlet UIView *mediaRenderView;
@property (weak, nonatomic) IBOutlet UIButton *stopButn;
@property (weak, nonatomic) IBOutlet UIButton *pauseButn;
@property (weak, nonatomic) IBOutlet UIButton *resumeButn;
@property (weak, nonatomic) IBOutlet UISlider *playerVolumeSlider;
@property (weak, nonatomic) IBOutlet UISwitch *enableAudioMixSwitch;

@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *soundEffectBtns;

@property (strong, nonatomic) NSMutableSet<NSNumber*>* unloadSoundEffectIDs;

@property (nonatomic) int playVolume;
@property (nonatomic) BOOL micEnabled;
@property (nonatomic) BOOL audioMixEnabled;

@property (nonatomic) ZegoLiveRoomApi *zegoApi;
@property (nonatomic) ZegoAudioPlayer *audioPlayer;

@end

@implementation ZGAudioPlayerPublishStreamVC

+ (instancetype)instanceFromStoryboard {
    return [[UIStoryboard storyboardWithName:@"AudioPlayer" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass([ZGAudioPlayerPublishStreamVC class])];
}

- (void)dealloc {
    NSLog(@"%@ dealloc", [self class]);
    [_audioPlayer stopAll];
    [_zegoApi stopPublishing];
    [_zegoApi logoutRoom];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupInitializeValue];
    [self setupZegoComponents];
    [self preloadSoundEffects];
    [self startLive];
}

#pragma mark - Actions

- (IBAction)playerVolumeChanged:(UISlider*)sender {
    self.playVolume = sender.value;
    [self.audioPlayer setVolumeAll:self.playVolume];
}

- (IBAction)enableAudioMixChanged:(UISwitch*)sender {
    self.audioMixEnabled = sender.isOn;
}

- (IBAction)stopButnClick:(id)sender {
    [self.audioPlayer stopAll];
}

- (IBAction)pauseButnClick:(id)sender {
    [self.audioPlayer pauseAll];
}

- (IBAction)resumeButnClick:(id)sender {
    [self.audioPlayer resumeAll];
}

- (IBAction)soundEffectBtnClick:(UIButton *)sender {
    unsigned int soundID = (unsigned int)sender.tag;
    [self.audioPlayer playEffect:soundID source:nil loop:0 publish:self.audioMixEnabled];
}

#pragma mark - private methods

- (void)preloadSoundEffects {
    [ZegoHudManager showNetworkLoading];
    
    NSArray<NSString*>* paths = [self searchPathForSoundEffects];
    [paths enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        unsigned int soundID = (unsigned int)(idx + 1);
        [self.audioPlayer preloadEffect:soundID source:obj];
    }];
}

- (NSArray<NSString*>*)searchPathForSoundEffects {
    NSMutableArray<NSString*>* paths = [NSMutableArray array];
    
    for (int i = 1; i < 7; ++i) {
        NSString *sourceName = [NSString stringWithFormat:@"sound_effect_%d", i];
        NSString *path = [NSBundle.mainBundle pathForResource:sourceName ofType:@"mp3"];
        [paths addObject:path];
    }
    
    return paths;
}

- (void)startLive {
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
        
        // 开始推流
        ZGLogInfo(@"请求推流");
        [self.zegoApi startPublishing:streamID title:nil flag:ZEGO_SINGLE_ANCHOR];
    }];
}

- (void)setupZegoComponents {
    ZGAppGlobalConfig *appConfig = [[ZGAppGlobalConfigManager sharedInstance] globalConfig];
    
    // 设置环境
    [ZegoLiveRoomApi setUseTestEnv:(appConfig.environment == ZGAppEnvironmentTest)];
    // 设置硬编硬解
    [ZegoLiveRoomApi requireHardwareEncoder:appConfig.openHardwareEncode];
    [ZegoLiveRoomApi requireHardwareDecoder:appConfig.openHardwareDecode];
    
    // setup zegoApi
    self.zegoApi = [[ZegoLiveRoomApi alloc] initWithAppID:appConfig.appID appSignature:[ZGAppSignHelper convertAppSignFromString:appConfig.appSign]];
    [self.zegoApi setRoomDelegate:self];
    [self.zegoApi setPublisherDelegate:self];
    
    // setup audio player
    ZegoAudioPlayer *audioPlayer = [[ZegoAudioPlayer alloc] init];
    [audioPlayer setVolumeAll:self.playVolume];
    [audioPlayer setDelegate:self];
    self.audioPlayer = audioPlayer;
    
    [self.zegoApi enableCamera:false];//音效模块不推视频流
}

- (void)setupInitializeValue {
    // 初始化默认设置值
    self.playVolume = 80;
    self.micEnabled = YES;
    self.audioMixEnabled = YES;
    self.unloadSoundEffectIDs = [NSMutableSet setWithObjects:@(1),@(2),@(3),@(4),@(5),@(6), nil];
    self.navigationItem.title = @"音频播放器&推流";
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

- (void)onPublishQualityUpdate:(NSString *)streamID quality:(ZegoApiPublishQuality)quality {
    NSLog(@"推流质量。fps:%f,vencFps:%f,videoBitrate:%f, quanlity:%d, width:%d, height:%d", quality.fps, quality.vencFps, quality.kbps, quality.quality, quality.width, quality.height);
}

#pragma mark - ZegoAudioPlayerDelegate

- (void)onPlayEffect:(unsigned int)soundID error:(int)error {
    if (error == 0) {
        ZGLogInfo(@"开始播放音效:%u", soundID);
    }
    else {
        ZGLogError(@"播放音效错误:%u， 错误码:%d", soundID, error);
    }
}

- (void)onPlayEnd:(unsigned int)soundID {
    ZGLogInfo(@"播放音效完成:%u", soundID);
}

- (void)onPreloadEffect:(unsigned int)soundID error:(int)error {
    if (error != 0) {
        [ZegoHudManager hideNetworkLoading];
        NSString *msg = [NSString stringWithFormat:@"预加载音效失败:%u", soundID];
        [ZegoHudManager showMessage:msg];
        ZGLogError(@"预加载音效失败:%u", soundID);
    }
    else {
        ZGLogInfo(@"预加载音效完成:%u", soundID);
    }
}

- (void)onPreloadComplete:(unsigned int)soundID {
    [self.unloadSoundEffectIDs removeObject:@(soundID)];
    
    if (self.unloadSoundEffectIDs.count == 0) {
        [ZegoHudManager hideNetworkLoading];
    }
}

@end
#endif
