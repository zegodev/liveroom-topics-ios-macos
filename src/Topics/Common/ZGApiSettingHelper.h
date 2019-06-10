//
//  ZGApiSettingHelper.h
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/4/24.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ZegoLiveRoom/ZegoLiveRoom.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZGApiSettingHelper : NSObject

//推流设置
@property (assign, nonatomic, readonly) int fps;
@property (assign, nonatomic, readonly) int bitrate;
@property (assign, nonatomic, readonly) CGSize resolution;
@property (assign, nonatomic, readonly) BOOL enableMic;
@property (assign, nonatomic, readonly) BOOL enableCam;
@property (assign, nonatomic, readonly) BOOL useFrontCam;
@property (assign, nonatomic, readonly) BOOL previewMirror;
@property (assign, nonatomic, readonly) ZegoVideoViewMode previewViewMode;

//拉流设置
@property (assign, nonatomic, readonly) int playVolume;
@property (assign, nonatomic, readonly) ZegoVideoViewMode playViewMode;
@property (assign, nonatomic, readonly) BOOL enableSpeaker;

//其他设置
@property (assign, nonatomic, readonly) BOOL useTestEnv;
@property (assign, nonatomic, readonly) BOOL enableHardwareEncode;
@property (assign, nonatomic, readonly) BOOL enableHardwareDecode;

+ (instancetype)shared;

- (void)reset;

- (BOOL)setFpsValue:(int)fps;
- (BOOL)setBitrateValue:(int)bitrate;
- (BOOL)setResolutionValue:(CGSize)resolution;
- (BOOL)setEnableMicValue:(BOOL)enableMic;
- (BOOL)setEnableCamValue:(BOOL)enableCam;
- (BOOL)setUseFrontCamValue:(BOOL)useFrontCam;
- (BOOL)setPreviewViewModeValue:(ZegoVideoViewMode)mode;
- (BOOL)setPreviewMirrorValue:(BOOL)previewMirror;

- (BOOL)setPlayVolumeValue:(int)playVolume;
- (BOOL)setPlayViewModeValue:(ZegoVideoViewMode)mode;
- (BOOL)setEnableSpeakerValue:(BOOL)enable;

- (BOOL)setSDKUseTestEnv:(BOOL)useTestEnv;
- (BOOL)setSDKEnableHardwareEncode:(BOOL)enable;
- (BOOL)setSDKEnableHardwareDecode:(BOOL)enable;

@end

NS_ASSUME_NONNULL_END
