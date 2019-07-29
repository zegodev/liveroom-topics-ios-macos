//
//  ZGApiSettingHelper.m
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/4/24.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGApiSettingHelper.h"

@interface ZGApiSettingHelper ()

//推流设置
@property (assign, nonatomic) int fps;
@property (assign, nonatomic) int bitrate;
@property (assign, nonatomic) CGSize resolution;
@property (assign, nonatomic) BOOL enableMic;
@property (assign, nonatomic) BOOL enableCam;
@property (assign, nonatomic) BOOL useFrontCam;
@property (assign, nonatomic) BOOL previewMirror;
@property (assign, nonatomic) ZegoVideoViewMode previewViewMode;

//拉流设置
@property (assign, nonatomic) int playVolume;
@property (assign, nonatomic) ZegoVideoViewMode playViewMode;
@property (assign, nonatomic) BOOL enableSpeaker;

//其他设置
@property (assign, nonatomic) BOOL useTestEnv;
@property (assign, nonatomic) BOOL enableHardwareEncode;
@property (assign, nonatomic) BOOL enableHardwareDecode;

@end

//publish
static const int ZGApiDefaultFps = 15;
static const int ZGApiDefaultBitrate = 1200000;
static const CGSize ZGApiDefaultResolution = {540,960};
static const BOOL ZGApiDefaultEnableMic = YES;
static const BOOL ZGApiDefaultEnableCam = YES;
static const BOOL ZGApiDefaultUseFrontCam = YES;
static const BOOL ZGApiDefaultPreviewMirror = YES;
static const ZegoVideoViewMode ZGApiDefaultPreviewViewMode = ZegoVideoViewModeScaleAspectFill;
//play
static const int ZGApiDefaultPlayVolume = 100;
static const ZegoVideoViewMode ZGApiDefaultPlayViewMode = ZegoVideoViewModeScaleAspectFill;
static const BOOL ZGApiDefaultEnableSpeaker = YES;
//class
static const BOOL ZGApiDefaultUseTestEnv = NO;
static const BOOL ZGApiDefaultEnableHardwareEncode = NO;
static const BOOL ZGApiDefaultEnableHardwareDecode = NO;


@implementation ZGApiSettingHelper

+ (instancetype)shared {
    static id instance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

- (void)reset {
    [self setFpsValue:ZGApiDefaultFps];
    [self setBitrateValue:ZGApiDefaultBitrate];
    [self setResolutionValue:ZGApiDefaultResolution];
    [self setEnableMicValue:ZGApiDefaultEnableMic];
    [self setEnableCamValue:ZGApiDefaultEnableCam];
    [self setUseFrontCamValue:ZGApiDefaultUseFrontCam];
    [self setPreviewMirrorValue:ZGApiDefaultPreviewMirror];
    [self setPreviewViewModeValue:ZGApiDefaultPreviewViewMode];
    
    [self setPlayVolumeValue:ZGApiDefaultPlayVolume];
    [self setPlayViewModeValue:ZGApiDefaultPlayViewMode];
    [self setEnableSpeakerValue:ZGApiDefaultEnableSpeaker];
    
//    [self setSDKUseTestEnv:ZGApiDefaultUseTestEnv];//环境配置需要持久化，暂不还原
    [self setSDKEnableHardwareEncode:ZGApiDefaultEnableHardwareEncode];
    [self setSDKEnableHardwareDecode:ZGApiDefaultEnableHardwareDecode];
}

- (int)fps {
    NSNumber *value = [self savedValueForKey:NSStringFromSelector(@selector(fps))];
    return value ? value.intValue:ZGApiDefaultFps;
}

- (BOOL)setFpsValue:(int)fps {
    ZegoAVConfig *config = [self avConfigWithFps:fps bitrate:self.bitrate resolution:self.resolution];
    
    bool result = [ZGApiManager.api setAVConfig:config];
    
    ZGLogInfo(@"设置推流帧率:%d",fps);
    
    if (result) {
        [self saveValue:@(fps) forKey:NSStringFromSelector(@selector(fps))];
        self.fps = fps;
        
        return YES;
    }
    else {
        ZGLogWarn(@"设置推流帧率失败");
        return NO;
    }
}

- (int)bitrate {
    NSNumber *value = [self savedValueForKey:NSStringFromSelector(@selector(bitrate))];
    return value ? value.intValue:ZGApiDefaultBitrate;
}

- (BOOL)setBitrateValue:(int)bitrate {
    ZegoAVConfig *config = [self avConfigWithFps:self.fps bitrate:bitrate resolution:self.resolution];
    
    bool result = [ZGApiManager.api setAVConfig:config];
    
    ZGLogInfo(@"设置推流视频比特率:%d",bitrate);
    
    if (result) {
        [self saveValue:@(bitrate) forKey:NSStringFromSelector(@selector(bitrate))];
        self.bitrate = bitrate;
        
        return YES;
    }
    else {
        ZGLogWarn(@"设置推流视频比特率失败");
        return NO;
    }
}

- (CGSize)resolution {
    NSString *formatString = [self savedValueForKey:NSStringFromSelector(@selector(resolution))];
    
    return formatString ? [self sizeFromString:formatString]:ZGApiDefaultResolution;
}

- (BOOL)setResolutionValue:(CGSize)resolution {
    ZegoAVConfig *config = [self avConfigWithFps:self.fps bitrate:self.bitrate resolution:resolution];
    
    bool result = [ZGApiManager.api setAVConfig:config];
    
    NSString *formatString = [self formatStringFromSize:resolution];

    ZGLogInfo(@"设置推流采集、编码分辨率:width=%f,height=%f",resolution.width, resolution.height);
    
    if (result) {
        [self saveValue:formatString forKey:NSStringFromSelector(@selector(resolution))];
        self.resolution = resolution;
        
        return YES;
    }
    else {
        ZGLogWarn(@"设置推流采集、编码分辨率失败");
        return NO;
    }
}

- (BOOL)enableMic {
    NSNumber *value = [self savedValueForKey:NSStringFromSelector(@selector(enableMic))];
    return value ? value.boolValue:ZGApiDefaultEnableMic;
}

- (BOOL)setEnableMicValue:(BOOL)enableMic {
    bool result = [ZGApiManager.api enableMic:enableMic];
    
    ZGLogInfo(@"设置开启麦克风:%@",enableMic ? @"Y":@"N");
    
    if (result) {
        [self saveValue:@(enableMic) forKey:NSStringFromSelector(@selector(enableMic))];
        self.enableMic = enableMic;
        
        return YES;
    }
    else {
        ZGLogWarn(@"设置开启麦克风失败");
        return NO;
    }
}

- (BOOL)enableCam {
    NSNumber *value = [self savedValueForKey:NSStringFromSelector(@selector(enableCam))];
    return value ? value.boolValue:ZGApiDefaultEnableCam;
}

- (BOOL)setEnableCamValue:(BOOL)enableCam {
    bool result = [ZGApiManager.api enableCamera:enableCam];
    
    ZGLogInfo(@"设置开启摄像头:%@",enableCam ? @"Y":@"N");
    
    if (result) {
        [self saveValue:@(enableCam) forKey:NSStringFromSelector(@selector(enableCam))];
        self.enableCam = enableCam;
        
        return YES;
    }
    else {
        ZGLogWarn(@"设置开启摄像头失败");
        return NO;
    }
}

- (BOOL)useFrontCam {
    NSNumber *value = [self savedValueForKey:NSStringFromSelector(@selector(useFrontCam))];
    return value ? value.boolValue:ZGApiDefaultUseFrontCam;
}

- (BOOL)setUseFrontCamValue:(BOOL)useFrontCam {
    bool result = [ZGApiManager.api setFrontCam:useFrontCam];
    
    ZGLogInfo(@"设置使用前置摄像头:%@",useFrontCam ? @"Y":@"N");
    
    if (result) {
        [self saveValue:@(useFrontCam) forKey:NSStringFromSelector(@selector(useFrontCam))];
        self.useFrontCam = useFrontCam;
        
        return YES;
    }
    else {
        ZGLogWarn(@"设置使用前置摄像头失败");
        return NO;
    }
}

- (ZegoVideoViewMode)previewViewMode {
    NSNumber *value = [self savedValueForKey:NSStringFromSelector(@selector(previewViewMode))];
    return value ? value.intValue:ZGApiDefaultPreviewViewMode;
}

- (BOOL)setPreviewViewModeValue:(ZegoVideoViewMode)mode {
    bool result = [ZGApiManager.api setPreviewViewMode:mode];
    
    ZGLogInfo(@"设置本地预览视频视图模式:%d",mode);
    
    if (result) {
        [self saveValue:@(mode) forKey:NSStringFromSelector(@selector(previewViewMode))];
        self.previewViewMode = mode;
        
        return YES;
    }
    else {
        ZGLogWarn(@"设置本地预览视频视图模式失败");
        return NO;
    }
}

- (BOOL)previewMirror {
    NSNumber *value = [self savedValueForKey:NSStringFromSelector(@selector(previewMirror))];
    return value ? value.boolValue:ZGApiDefaultPreviewMirror;
}

- (BOOL)setPreviewMirrorValue:(BOOL)previewMirror {
    ZegoVideoMirrorMode mode = previewMirror ? ZegoVideoMirrorModePreviewMirrorPublishNoMirror:ZegoVideoMirrorModePreviewCaptureBothNoMirror;
    bool result = [ZGApiManager.api setVideoMirrorMode:mode];
    
    ZGLogInfo(@"设置预览镜像:%@",previewMirror ? @"Y":@"N");
    
    if (result) {
        [self saveValue:@(previewMirror) forKey:NSStringFromSelector(@selector(previewMirror))];
        self.previewMirror = previewMirror;
        
        return YES;
    }
    else {
        ZGLogWarn(@"设置预览镜像失败");
        return NO;
    }
}

- (int)playVolume {
    NSNumber *value = [self savedValueForKey:NSStringFromSelector(@selector(playVolume))];
    return value ? value.intValue:ZGApiDefaultPlayVolume;
}

- (BOOL)setPlayVolumeValue:(int)playVolume {
    bool result = [ZGApiManager.api setPlayVolume:playVolume];
    
    ZGLogInfo(@"设置所有拉流的播放音量:%d",playVolume);
    
    if (result) {
        [self saveValue:@(playVolume) forKey:NSStringFromSelector(@selector(playVolume))];
        self.playVolume = playVolume;
        
        return YES;
    }
    else {
        ZGLogWarn(@"设置所有拉流的播放音量失败");
        return NO;
    }
}

- (ZegoVideoViewMode)playViewMode {
    NSNumber *value = [self savedValueForKey:NSStringFromSelector(@selector(playViewMode))];
    return value ? value.intValue:ZGApiDefaultPlayViewMode;
}

- (BOOL)setPlayViewModeValue:(ZegoVideoViewMode)mode {
    // 需要指定流名设置
    ZGLogInfo(@"设置本地默认预览视频视图模式:%d",mode);
    
    [self saveValue:@(mode) forKey:NSStringFromSelector(@selector(playViewMode))];
    self.playViewMode = mode;
    
    return YES;
}

- (BOOL)enableSpeaker {
    NSNumber *value = [self savedValueForKey:NSStringFromSelector(@selector(enableSpeaker))];
    return value ? value.boolValue:ZGApiDefaultEnableSpeaker;
}

- (BOOL)setEnableSpeakerValue:(BOOL)enable {
    bool result = [ZGApiManager.api enableSpeaker:enable];
    
    ZGLogInfo(@"设置使用扬声器:%@",enable ? @"Y":@"N");
    
    if (result) {
        [self saveValue:@(enable) forKey:NSStringFromSelector(@selector(enableSpeaker))];
        self.enableSpeaker = enable;
        
        return YES;
    }
    else {
        ZGLogWarn(@"设置使用扬声器失败");
        return NO;
    }
}

- (BOOL)useTestEnv {
    NSNumber *value = [self savedValueForKey:NSStringFromSelector(@selector(useTestEnv))];
    return value ? value.boolValue:ZGApiDefaultUseTestEnv;
}

- (BOOL)setSDKUseTestEnv:(BOOL)useTestEnv {
    [ZegoLiveRoomApi setUseTestEnv:useTestEnv];
    
    ZGLogInfo(@"设置SDK环境:%@",useTestEnv ? @"测试":@"正式");

    [self saveValue:@(useTestEnv) forKey:NSStringFromSelector(@selector(useTestEnv))];
    self.useTestEnv = useTestEnv;    
    
    return YES;
}

- (BOOL)enableHardwareEncode {
    NSNumber *value = [self savedValueForKey:NSStringFromSelector(@selector(enableHardwareEncode))];
    return value ? value.boolValue:ZGApiDefaultEnableHardwareEncode;
}

- (BOOL)setSDKEnableHardwareEncode:(BOOL)enable {
    bool result = [ZegoLiveRoomApi requireHardwareEncoder:enable];
    
    ZGLogInfo(@"设置硬件编码:%@",enable ? @"Y":@"N");
    
    if (result) {
        [self saveValue:@(enable) forKey:NSStringFromSelector(@selector(enableHardwareEncode))];
        self.enableHardwareEncode = enable;

        return YES;
    }
    else {
        ZGLogWarn(@"设置硬件编码失败");
        return NO;
    }
}

- (BOOL)enableHardwareDecode {
    NSNumber *value = [self savedValueForKey:NSStringFromSelector(@selector(enableHardwareDecode))];
    return value ? value.boolValue:ZGApiDefaultEnableHardwareDecode;
}

- (BOOL)setSDKEnableHardwareDecode:(BOOL)enable {
    bool result = [ZegoLiveRoomApi requireHardwareDecoder:enable];
    
    ZGLogInfo(@"设置硬件解码:%@",enable ? @"Y":@"N");
    
    if (result) {
        [self saveValue:@(enable) forKey:NSStringFromSelector(@selector(enableHardwareDecode))];
        self.enableHardwareDecode = enable;
        
        return YES;
    }
    else {
        ZGLogWarn(@"设置硬件解码失败");
        return NO;
    }
}

- (ZegoAVConfig *)avConfigWithFps:(int)fps bitrate:(int)bitrate resolution:(CGSize)resolution {
    ZegoAVConfig *config = [ZegoAVConfig new];
    config.videoEncodeResolution = resolution;
    config.videoCaptureResolution = resolution;
    config.fps = fps;
    config.bitrate = bitrate;
    
    return config;
}


#pragma mark - Others

- (CGSize)sizeFromString:(NSString *)formatString {
    NSData *data = [formatString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
    NSNumber *w = dic[@"width"];
    NSNumber *h = dic[@"height"];
    if (!w || !h) {
        return ZGApiDefaultResolution;
    }
    return CGSizeMake(w.doubleValue, h.doubleValue);
}

- (NSString *)formatStringFromSize:(CGSize)size {
    NSDictionary *dic = @{@"width":@(size.width),
                          @"height":@(size.height)};
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end
