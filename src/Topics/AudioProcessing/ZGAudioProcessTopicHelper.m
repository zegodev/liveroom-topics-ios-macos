//
//  ZGAudioProcessTopicHelper.m
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/8/28.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_AudioProcessing

#import "ZGAudioProcessTopicHelper.h"
#if TARGET_OS_IOS
#import <ZegoLiveRoom/zego-api-audio-processing-oc.h>
#elif TARGET_OS_OSX
#import <ZegoLiveRoomOSX/zego-api-audio-processing-oc.h>
#endif

@implementation ZGAudioProcessTopicConfigMode

+ (instancetype)modeWithModeValue:(NSNumber * _Nullable)modeValue modeName:(NSString *)modeName isCustom:(BOOL)isCustom {
    ZGAudioProcessTopicConfigMode *m = [[ZGAudioProcessTopicConfigMode alloc] init];
    m.modeValue = modeValue;
    m.modeName = modeName;
    m.isCustom = isCustom;
    return m;
}

@end

@implementation ZGAudioProcessTopicHelper

+ (NSArray<ZGAudioProcessTopicConfigMode*>*)voiceChangerOptionModes {
    static dispatch_once_t onceToken;
    static NSArray<ZGAudioProcessTopicConfigMode*> *_voiceChangerOptionModes = nil;
    dispatch_once(&onceToken, ^{
        _voiceChangerOptionModes =
        @[[ZGAudioProcessTopicConfigMode modeWithModeValue:@(ZEGOAPI_VOICE_CHANGER_WOMEN_TO_MEN) modeName:@"女声变男声" isCustom:NO],
          [ZGAudioProcessTopicConfigMode modeWithModeValue:@(ZEGOAPI_VOICE_CHANGER_MEN_TO_WOMEN) modeName:@"男声变女声" isCustom:NO],
          [ZGAudioProcessTopicConfigMode modeWithModeValue:@(ZEGOAPI_VOICE_CHANGER_WOMEN_TO_CHILD) modeName:@"女声变童声" isCustom:NO],
          [ZGAudioProcessTopicConfigMode modeWithModeValue:@(ZEGOAPI_VOICE_CHANGER_MEN_TO_CHILD) modeName:@"男声变童声" isCustom:NO],
          [ZGAudioProcessTopicConfigMode modeWithModeValue:nil modeName:@"自定义" isCustom:YES]];
    });
    return _voiceChangerOptionModes;
}

+ (NSArray<ZGAudioProcessTopicConfigMode*>*)reverbOptionModes {
    static dispatch_once_t onceToken;
    static NSArray<ZGAudioProcessTopicConfigMode*> *_reverbOptionModes = nil;
    dispatch_once(&onceToken, ^{
        _reverbOptionModes =
        @[[ZGAudioProcessTopicConfigMode modeWithModeValue:@(ZEGOAPI_AUDIO_REVERB_MODE_CONCERT_HALL) modeName:@"音乐厅" isCustom:NO],
          [ZGAudioProcessTopicConfigMode modeWithModeValue:@(ZEGOAPI_AUDIO_REVERB_MODE_LARGE_AUDITORIUM) modeName:@"大教堂" isCustom:NO],
          [ZGAudioProcessTopicConfigMode modeWithModeValue:@(ZEGOAPI_AUDIO_REVERB_MODE_WARM_CLUB) modeName:@"俱乐部" isCustom:NO],
          [ZGAudioProcessTopicConfigMode modeWithModeValue:@(ZEGOAPI_AUDIO_REVERB_MODE_SOFT_ROOM) modeName:@"房间" isCustom:NO],
          [ZGAudioProcessTopicConfigMode modeWithModeValue:nil modeName:@"自定义" isCustom:YES]];
    });
    return _reverbOptionModes;
}

@end
#endif
