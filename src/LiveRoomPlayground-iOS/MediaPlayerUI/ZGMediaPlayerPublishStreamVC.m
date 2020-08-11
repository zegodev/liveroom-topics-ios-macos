//
//  ZGMediaPlayerPublishStreamVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/23.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_MediaPlayer

#import "ZGMediaPlayerPublishStreamVC.h"
#import "ZGAppGlobalConfigManager.h"
#import "ZGAppSignHelper.h"
#import "ZGDemoExternalVideoCaptureFactory.h"
#import "ZGMediaPlayerVideoDataToPixelBufferConverter.h"
#import <ZegoLiveRoom/zego-api-mediaplayer-oc.h>

@interface ZGMediaPlayerPublishStreamVC () <ZegoRoomDelegate, ZegoLivePublisherDelegate, ZegoMediaPlayerEventWithIndexDelegate, ZegoMediaPlayerVideoPlayWithIndexDelegate>

@property (weak, nonatomic) IBOutlet UIView *mediaRenderView;
@property (weak, nonatomic) IBOutlet UIButton *playButn;
@property (weak, nonatomic) IBOutlet UIButton *stopButn;
@property (weak, nonatomic) IBOutlet UIButton *pauseButn;
@property (weak, nonatomic) IBOutlet UIButton *resumeButn;
@property (weak, nonatomic) IBOutlet UILabel *mediaDurationLabel;
@property (weak, nonatomic) IBOutlet UISlider *mediaPlayProcessSlider;
@property (weak, nonatomic) IBOutlet UISlider *playerVolumeSlider;
@property (weak, nonatomic) IBOutlet UISegmentedControl *audioTrackSegCtrl;
@property (weak, nonatomic) IBOutlet UISwitch *enableMicSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *enableAudioMixSwitch;

@property (nonatomic) int playVolume;
@property (nonatomic) BOOL micEnabled;
@property (nonatomic) BOOL audioMixEnabled;

@property (nonatomic) long mediaDuration;  // 资源的时间长度。单位：毫秒
@property (nonatomic) NSInteger audioTrackNum;  // 音轨数量
@property (nonatomic) NSInteger selectedAudioTrackIndexToPublish;// 所选用于推流的音轨

@property (nonatomic) ZegoLiveRoomApi *zegoApi;
@property (nonatomic) ZegoMediaPlayer *mediaPlayer;
@property (nonatomic) ZGDemoExternalVideoCaptureFactory *externalVideoCaptureFactory;
@property (nonatomic) ZGMediaPlayerVideoDataToPixelBufferConverter *playerVideoHandler;
@property (nonatomic) CGSize currentVideoEncodeResolution;

@end

@implementation ZGMediaPlayerPublishStreamVC

+ (instancetype)instanceFromStoryboard {
    return [[UIStoryboard storyboardWithName:@"NewMediaPlayer" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass([ZGMediaPlayerPublishStreamVC class])];
}

- (void)dealloc {
    NSLog(@"%@ dealloc", [self class]);

}

- (void)viewWillDisappear:(BOOL)animated
{
    [_mediaPlayer uninit];
    [_zegoApi stopPublishing];
    [_zegoApi logoutRoom];
    [ZegoExternalVideoCapture setVideoCaptureFactory:nil channelIndex:ZEGOAPI_CHN_MAIN];
    self.zegoApi = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 初始化默认设置值
    self.playVolume = 80;
    self.micEnabled = YES;
    self.audioMixEnabled = YES;
    self.mediaDuration = 0;
    self.audioTrackNum = 0;
    self.selectedAudioTrackIndexToPublish = 0;
    
    [self setupUI];
    [self setupZegoComponents];
    [self setupPlayerVideoHandler];
    [self preLoadMedia];
    [self startLive];
}

- (IBAction)playerVolumeChanged:(UISlider*)sender {
    self.playVolume = sender.value;
    [_mediaPlayer setVolume:self.playVolume];
}

- (IBAction)audioTrackSegCtrlChanged:(UISegmentedControl*)sender {
    self.selectedAudioTrackIndexToPublish = sender.selectedSegmentIndex;
    [_mediaPlayer setAudioStream:self.selectedAudioTrackIndexToPublish];
}

- (IBAction)enableMicChanged:(UISwitch*)sender {
    self.micEnabled = sender.isOn;
    [_zegoApi enableMic:self.micEnabled];
}

- (IBAction)enableAudioMixChanged:(UISwitch*)sender {
    self.audioMixEnabled = sender.isOn;
    [_mediaPlayer setPlayerType:self.audioMixEnabled?MediaPlayerTypeAux:MediaPlayerTypePlayer];
}

- (IBAction)playButnClick:(id)sender {
    NSString *url = self.mediaItem.fileUrl;
    [_mediaPlayer start:url repeat:YES];
}

- (IBAction)stopButnClick:(id)sender {
    [_mediaPlayer stop];
}

- (IBAction)pauseButnClick:(id)sender {
    [_mediaPlayer pause];
}

- (IBAction)resumeButnClick:(id)sender {
    [_mediaPlayer resume];
}

#pragma mark - private methods

- (void)preLoadMedia {
    Weakify(self)
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        Strongify(self)
        [self.mediaPlayer load:self.mediaItem.fileUrl];
    });
    
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

- (ZGDemoExternalVideoCaptureFactory *)externalVideoCaptureFactory {
    if (!_externalVideoCaptureFactory) {
        ZGDemoExternalVideoCaptureFactory *factory = [[ZGDemoExternalVideoCaptureFactory alloc] init];
        factory.onStartPreview = ^BOOL{
            return YES;
        };
        factory.onStopPreview = ^{
            
        };
        factory.onStartCapture = ^BOOL{
            return YES;
        };
        factory.onStopCapture = ^{
            
        };
        
        _externalVideoCaptureFactory = factory;
    }
    return _externalVideoCaptureFactory;
}

- (void)setupZegoComponents {
    ZGAppGlobalConfig *appConfig = [[ZGAppGlobalConfigManager sharedInstance] globalConfig];
    
    // 设置环境
    [ZegoLiveRoomApi setUseTestEnv:(appConfig.environment == ZGAppEnvironmentTest)];
    // 设置硬编硬解
    [ZegoLiveRoomApi requireHardwareEncoder:appConfig.openHardwareEncode];
    [ZegoLiveRoomApi requireHardwareDecoder:appConfig.openHardwareDecode];
    
    // configure ZegoLiveRoomApi context
    if (self.mediaItem.isVideo) {
        [ZegoExternalVideoCapture setVideoCaptureFactory:self.externalVideoCaptureFactory channelIndex:ZEGOAPI_CHN_MAIN];
    } else {
        [ZegoExternalVideoCapture setVideoCaptureFactory:nil channelIndex:ZEGOAPI_CHN_MAIN];
    }
    
    // setup zegoApi
    self.zegoApi = [[ZegoLiveRoomApi alloc] initWithAppID:appConfig.appID appSignature:[ZGAppSignHelper convertAppSignFromString:appConfig.appSign]];
    [self.zegoApi setRoomDelegate:self];
    [self.zegoApi setPublisherDelegate:self];
    if (self.mediaItem.isVideo) {
        [self.zegoApi enableCamera:YES];
    } else {
        [self.zegoApi enableCamera:NO];
    }
    
    // setup mediaPlayer。选择 MediaPlayerTypeAux 类型，将播放数据混入到推流中
    self.mediaPlayer = [[ZegoMediaPlayer alloc] initWithPlayerType:self.audioMixEnabled?MediaPlayerTypeAux:MediaPlayerTypePlayer playerIndex:ZegoMediaPlayerIndexFirst];
    [self.mediaPlayer setProcessInterval:500];
    [self.mediaPlayer setEventWithIndexDelegate:self];
    
    // Warning:由于 CVPixelBuffer 的限制，现在只支持将 BGRA，i420，NV12 格式转为 CVPixelBuffer
    // 所以请 iOS 开发者选择 BGRA，i420，NV12 类型
    [self.mediaPlayer setVideoPlayWithIndexDelegate:self format:ZegoMediaPlayerVideoPixelFormatNV12];
    BOOL ret = [self.mediaPlayer requireHWDecoder];
    NSLog(@"requireHWDecoder.ret:%d", ret);
    
    [self.mediaPlayer setView:self.mediaRenderView];
    [self.mediaPlayer setVolume:self.playVolume];
    [self.mediaPlayer setAudioStream:self.selectedAudioTrackIndexToPublish];
}

- (void)setupPlayerVideoHandler {
    _playerVideoHandler = [[ZGMediaPlayerVideoDataToPixelBufferConverter alloc] init];
}

- (void)setupUI {
    self.navigationItem.title = @"媒体播放器&推流";
    
    self.playButn.enabled = NO;
    self.stopButn.enabled = NO;
    self.pauseButn.enabled = NO;
    self.resumeButn.enabled = NO;
    
    self.mediaDurationLabel.text = @"--";
    self.mediaPlayProcessSlider.value = 0;
    self.audioTrackSegCtrl.hidden = YES;
    
    self.playerVolumeSlider.minimumValue = 0;
    self.playerVolumeSlider.maximumValue = 100;
    self.playerVolumeSlider.value = self.playVolume;
    
    self.enableMicSwitch.on = self.micEnabled;
    self.enableAudioMixSwitch.on = self.audioMixEnabled;
    
    [self invalidateAudioTrackSegCtrl];
}

- (void)invalidateAudioTrackSegCtrl {
    self.audioTrackSegCtrl.hidden = (self.audioTrackNum <= 0);
    [self.audioTrackSegCtrl removeAllSegments];
    if (self.audioTrackNum > 0) {
        for (NSInteger i = 0; i < self.audioTrackNum; i++) {
            [self.audioTrackSegCtrl insertSegmentWithTitle:@(i+1).stringValue atIndex:i animated:NO];
        }
        self.audioTrackSegCtrl.selectedSegmentIndex = self.selectedAudioTrackIndexToPublish;
    }
}

- (void)postMediaPlayerVideoFrameData:(CVImageBufferRef)buffer presentationTimeStamp:(CMTime)timestamp format:(struct ZegoMediaPlayerVideoDataFormat)format {
    
    // 设置推流的 videoEncodeResolution
    CGSize currentEncodeResolution = self.currentVideoEncodeResolution;
    if (currentEncodeResolution.width != format.width || currentEncodeResolution.height != format.height) {
        currentEncodeResolution.width = format.width;
        currentEncodeResolution.height = format.height;
        self.currentVideoEncodeResolution = currentEncodeResolution;
        
        ZegoAVConfig* config = [[ZegoAVConfig alloc] init];
        config.videoEncodeResolution = currentEncodeResolution;
        config.bitrate = 1200*1000;
        config.fps = 15;
        [self->_zegoApi setAVConfig:config];
    }
    
    [self->_externalVideoCaptureFactory postCapturedData:buffer withPresentationTimeStamp:timestamp];
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

#pragma mark - ZegoMediaPlayerEventWithIndexDelegate

/**
 开始播放
 */
- (void)onPlayStart:(ZegoMediaPlayerIndex)index {
    NSLog(@"%s", __func__);
}

/**
 暂停播放
 */
- (void)onPlayPause:(ZegoMediaPlayerIndex)index {
    NSLog(@"%s", __func__);
}

/**
 恢复播放
 */
- (void)onPlayResume:(ZegoMediaPlayerIndex)index {
    NSLog(@"%s", __func__);
}

/**
 播放错误
 */

- (void)onPlayError:(int)code playerIndex: (ZegoMediaPlayerIndex)index{

    NSLog(@"%s, code:%d", __func__, code);
}

/**
 播放结束
 */
- (void)onPlayEnd:(ZegoMediaPlayerIndex)index {
    NSLog(@"%s", __func__);
}

/**
 用户停止播放的回调
 */
- (void)onPlayStop:(ZegoMediaPlayerIndex)index {
    NSLog(@"%s", __func__);
}

/**
 网络音乐资源播放不畅，开始尝试缓存数据。
 
 @warning 只有播放网络音乐资源才需要关注这个回调
 */
- (void)onBufferBegin:(ZegoMediaPlayerIndex)index {
    NSLog(@"%s", __func__);
}

/**
 网络音乐资源可以顺畅播放。
 
 @warning 只有播放网络音乐资源才需要关注这个回调
 */
- (void)onBufferEnd:(ZegoMediaPlayerIndex)index {
    NSLog(@"%s", __func__);
}

/**
 快进到指定时刻
 
 @param code >=0 成功，其它表示失败
 @param millisecond 实际快进的进度，单位毫秒
 */

- (void)onSeekComplete:(int)code when:(long)millisecond playerIndex: (ZegoMediaPlayerIndex)index{
    NSLog(@"%s", __func__);
}

/**
 预加载完成
 */
- (void)onLoadComplete:(ZegoMediaPlayerIndex)index {
    NSLog(@"%s", __func__);
    
    self.playButn.enabled = YES;
    self.stopButn.enabled = YES;
    self.pauseButn.enabled = YES;
    self.resumeButn.enabled = YES;
    
    // 可以获取 mediaPlayer 的播放资源的参数了
    self.mediaDuration = [_mediaPlayer getDuration];
    self.audioTrackNum = [_mediaPlayer getAudioStreamCount];
    self.selectedAudioTrackIndexToPublish = 0;
    
    _mediaPlayProcessSlider.minimumValue = 0;
    _mediaPlayProcessSlider.maximumValue = self.mediaDuration;
    _mediaDurationLabel.text = [NSString stringWithFormat:@"%@ s", @(self.mediaDuration/1000)];
    
    [_mediaPlayer setAudioStream:self.selectedAudioTrackIndexToPublish];
    [_mediaPlayer enableRepeatMode:YES];
    [self invalidateAudioTrackSegCtrl];
}

/**
 播放进度回调
 
 @param timestamp 当前播放进度，单位毫秒
 @note 同步回调，请不要在回调中处理数据或做其他耗时操作
 */

- (void)onProcessInterval:(long)timestamp playerIndex: (ZegoMediaPlayerIndex)index{

    NSLog(@"%s", __func__);
    // 切换到主线程更新 UI
    dispatch_async(dispatch_get_main_queue(), ^{
        self.mediaPlayProcessSlider.value = timestamp;
    });
}

#pragma mark - ZegoMediaPlayerVideoPlayDelegate

/**
 视频帧数据回调
 
 @param data 视频帧原始数据
 @param size 视频帧原始数据大小
 @param format 视频帧原始数据格式
 @note 同步回调，请不要在回调中处理数据或做其他耗时操作
 */

- (void)onPlayVideoData:(const char *)data size:(int)size format:(struct ZegoMediaPlayerVideoDataFormat)format playerIndex:(ZegoMediaPlayerIndex)index{
    // 注意：不要在另外的线程处理 data，因为 data 可能会被释放
    Weakify(self);
    [self.playerVideoHandler convertRGBCategoryDataToPixelBufferWithVideoData:data size:size format:format completion:^(ZGMediaPlayerVideoDataToPixelBufferConverter * _Nonnull converter, CVPixelBufferRef  _Nonnull buffer, CMTime timestamp) {
        Strongify(self);
        [self postMediaPlayerVideoFrameData:buffer presentationTimeStamp:timestamp format:format];
    }];
}

- (void)onPlayVideoData2:(const char **)data size:(int *)size format:(struct ZegoMediaPlayerVideoDataFormat)format playerIndex:(ZegoMediaPlayerIndex)index{

    // 注意：不要在另外的线程处理 data，因为 data 可能会被释放
    Weakify(self);
    [self.playerVideoHandler convertYUVCategoryDataToPixelBufferWithVideoData:data size:size format:format completion:^(ZGMediaPlayerVideoDataToPixelBufferConverter * _Nonnull converter, CVPixelBufferRef  _Nonnull buffer, CMTime timestamp) {
        Strongify(self);
        [self postMediaPlayerVideoFrameData:buffer presentationTimeStamp:timestamp format:format];
    }];
}

@end
#endif
