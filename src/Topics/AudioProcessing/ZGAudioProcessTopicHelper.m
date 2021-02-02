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
        NSArray *voiceChangerTypes = @[
            @(ZEGOAPI_VOICE_CHANGER_TYPE_CHANGER_OFF),
            @(ZEGOAPI_VOICE_CHANGER_TYPE_OPTIMUS_PRIME),
            @(ZEGOAPI_VOICE_CHANGER_TYPE_AI_ROBOT),
            @(ZEGOAPI_VOICE_CHANGER_TYPE_FOREIGNER),
            @(ZEGOAPI_VOICE_CHANGER_TYPE_ELUSIVE),
            @(ZEGOAPI_VOICE_CHANGER_TYPE_MALE_MAGNETIC),
            @(ZEGOAPI_VOICE_CHANGER_TYPE_FEMALE_FRESH),
            @(ZEGOAPI_VOICE_CHANGER_TYPE_MEN_TO_CHILD),
            @(ZEGOAPI_VOICE_CHANGER_TYPE_MEN_TO_WOMEN),
            @(ZEGOAPI_VOICE_CHANGER_TYPE_WOMEN_TO_CHILD),
            @(ZEGOAPI_VOICE_CHANGER_TYPE_WOMEN_TO_MEN)
        ];
        NSArray *voiceChangerTitles = @[
            @"恢复原声",
            @"擎天柱",
            @"AI 机器人",
            @"外国人",
            @"空灵",
            @"磁性男声",
            @"清新女声",
            @"男声变童",
            @"男声变女",
            @"女声变童",
            @"女声变男",
        ];
        NSMutableArray *modes = [@[] mutableCopy];
        [voiceChangerTypes enumerateObjectsUsingBlock:^(NSNumber*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *title = [voiceChangerTitles objectAtIndex:idx];
            ZGAudioProcessTopicConfigMode * configMode = [ZGAudioProcessTopicConfigMode modeWithModeValue:obj modeName:title isCustom:NO];
            [modes addObject:configMode];
        }];
        _voiceChangerOptionModes = [modes copy];
    });
    return _voiceChangerOptionModes;
}

+ (NSArray<ZGAudioProcessTopicConfigMode*>*)reverbOptionModes {
    static dispatch_once_t onceToken;
    static NSArray<ZGAudioProcessTopicConfigMode*> *_reverbOptionModes = nil;
    dispatch_once(&onceToken, ^{
        NSArray *voiceReverbTypes = @[
            @(ZEGO_AUDIO_REVERB_TYPE_OFF),
            @(ZEGO_AUDIO_REVERB_TYPE_SOFT_ROOM),
            @(ZEGO_AUDIO_REVERB_TYPE_WARM_CLUB),
            @(ZEGO_AUDIO_REVERB_TYPE_CONCERT_HALL),
            @(ZEGO_AUDIO_REVERB_TYPE_LARGE_AUDITORIUM),
            @(ZEGO_AUDIO_REVERB_TYPE_RECORDING_STUDIO),
            @(ZEGO_AUDIO_REVERB_TYPE_BASEMENT),
            @(ZEGO_AUDIO_REVERB_TYPE_KTV),
            @(ZEGO_AUDIO_REVERB_TYPE_POPULAR),
            @(ZEGO_AUDIO_REVERB_TYPE_ROCK),
            @(ZEGO_AUDIO_REVERB_TYPE_VOCAL_CONCERT),
        ];
        NSArray *voiceReverbTitles = @[
            @"关闭混响",
            @"房间模式",
            @"俱乐部（大房间）",
            @"音乐厅",
            @"大教堂",
            @"录音棚",
            @"地下室",
            @"KTV",
            @"流行",
            @"摇滚",
            @"演唱会",
        ];
        NSMutableArray *modes = [@[] mutableCopy];
        [voiceReverbTypes enumerateObjectsUsingBlock:^(NSNumber*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *title = [voiceReverbTitles objectAtIndex:idx];
            ZGAudioProcessTopicConfigMode * configMode = [ZGAudioProcessTopicConfigMode modeWithModeValue:obj modeName:title isCustom:NO];
            [modes addObject:configMode];
        }];
        _reverbOptionModes = [modes copy];
    });
    return _reverbOptionModes;
}

@end
#endif
