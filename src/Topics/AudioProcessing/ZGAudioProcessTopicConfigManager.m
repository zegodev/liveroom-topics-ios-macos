//
//  ZGAudioProcessTopicConfigManager.m
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/8/27.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_AudioProcessing

#import "ZGAudioProcessTopicConfigManager.h"
#import "ZGUserDefaults.h"
#import "ZGHashTableHelper.h"

NSString* const ZGAudioProcessTopicConfigVoiceChangerOpenKey = @"ZGAudioProcessTopicConfigVoiceChangerOpenKey";
NSString* const ZGAudioProcessTopicConfigVoiceChangerParamKey = @"ZGAudioProcessTopicConfigVoiceChangerParamKey";

NSString* const ZGAudioProcessTopicConfigVirtualStereoOpenKey = @"ZGAudioProcessTopicConfigVirtualStereoOpenKey";
NSString* const ZGAudioProcessTopicConfigVirtualStereoAngleKey = @"ZGAudioProcessTopicConfigVirtualStereoAngleKey";

NSString* const ZGAudioProcessTopicConfigReverbOpenKey = @"ZGAudioProcessTopicConfigReverbOpenKey";
NSString* const ZGAudioProcessTopicConfigReverbModeKey = @"ZGAudioProcessTopicConfigReverbModeKey";
NSString* const ZGAudioProcessTopicConfigCustomReverbRoomSizeKey = @"ZGAudioProcessTopicConfigCustomReverbRoomSizeKey";
NSString* const ZGAudioProcessTopicConfigCustomDryWetRatioKey = @"ZGAudioProcessTopicConfigCustomDryWetRatioKey";
NSString* const ZGAudioProcessTopicConfigCustomDampingKey = @"ZGAudioProcessTopicConfigCustomDampingKey";
NSString* const ZGAudioProcessTopicConfigCustomReverberanceKey = @"ZGAudioProcessTopicConfigCustomReverberanceKey";


@interface ZGAudioProcessTopicConfigManager ()
{
    dispatch_queue_t _configOptQueue;
}

@property (nonatomic) ZGUserDefaults *zgUserDefaults;
@property (nonatomic) NSHashTable *configChangedHandlers;

@end

@implementation ZGAudioProcessTopicConfigManager

static ZGAudioProcessTopicConfigManager *instance = nil;

#pragma mark - public methods

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    return [ZGAudioProcessTopicConfigManager sharedInstance];
}

- (id)copyWithZone:(struct _NSZone *)zone {
    return [ZGAudioProcessTopicConfigManager sharedInstance];
}

- (instancetype)init {
    if (self = [super init]) {
        _zgUserDefaults = [[ZGUserDefaults alloc] init];
        _configChangedHandlers = [ZGHashTableHelper createWeakReferenceHashTable];
        _configOptQueue = dispatch_queue_create("com.doudong.ZGAudioProcessTopicConfigOptQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)addConfigChangedHandler:(id<ZGAudioProcessTopicConfigChangedHandler>)handler {
    if (!handler) return;
    dispatch_async(_configOptQueue, ^{
        if (![self.configChangedHandlers containsObject:handler]) {
            [self.configChangedHandlers addObject:handler];
        }
    });
}

- (void)removeConfigChangedHandler:(id<ZGAudioProcessTopicConfigChangedHandler>)handler {
    if (!handler) return;
    dispatch_async(_configOptQueue, ^{
        [self.configChangedHandlers removeObject:handler];
    });
}

- (void)setCustomVoiceChangerOpen:(BOOL)customVoiceChangerOpen {
    _customVoiceChangerOpen = customVoiceChangerOpen;
    dispatch_async(_configOptQueue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<ZGAudioProcessTopicConfigChangedHandler> handler in self.configChangedHandlers) {
                if ([handler respondsToSelector:@selector(audioProcessTopicConfigManager:customVoiceChangerOpenChanged:)]) {
                    [handler audioProcessTopicConfigManager:self customVoiceChangerOpenChanged:customVoiceChangerOpen];
                }
            }
        });
    });
}

- (void)setVoiceChangerOpen:(BOOL)voiceChangerOpen {
    dispatch_async(_configOptQueue, ^{
        NSNumber *obj = @(voiceChangerOpen);
        [self.zgUserDefaults setObject:obj forKey:ZGAudioProcessTopicConfigVoiceChangerOpenKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<ZGAudioProcessTopicConfigChangedHandler> handler in self.configChangedHandlers) {
                if ([handler respondsToSelector:@selector(audioProcessTopicConfigManager:voiceChangerOpenChanged:)]) {
                    [handler audioProcessTopicConfigManager:self voiceChangerOpenChanged:voiceChangerOpen];
                }
            }
        });
    });
}

- (BOOL)voiceChangerOpen {
    __block BOOL isOpen = NO;
    dispatch_sync(_configOptQueue, ^{
        NSNumber *n = [self.zgUserDefaults objectForKey:ZGAudioProcessTopicConfigVoiceChangerOpenKey];
        if (n) {
            isOpen = [n boolValue];
        } else {
            // 设置默认
            isOpen = NO;
        }
    });
    return isOpen;
}

- (void)setVoiceChangerParam:(float)voiceChangerParam {
    dispatch_async(_configOptQueue, ^{
        NSNumber *obj = @(voiceChangerParam);
        [self.zgUserDefaults setObject:obj forKey:ZGAudioProcessTopicConfigVoiceChangerParamKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<ZGAudioProcessTopicConfigChangedHandler> handler in self.configChangedHandlers) {
                if ([handler respondsToSelector:@selector(audioProcessTopicConfigManager:voiceChangerParamChanged:)]) {
                    [handler audioProcessTopicConfigManager:self voiceChangerParamChanged:voiceChangerParam];
                }
            }
        });
    });
}

- (void)setVoiceChangerType:(NSUInteger)voiceChangerType {
    _voiceChangerType = voiceChangerType;
    dispatch_async(_configOptQueue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<ZGAudioProcessTopicConfigChangedHandler> handler in self.configChangedHandlers) {
                if ([handler respondsToSelector:@selector(audioProcessTopicConfigManager:voiceChangerTypeChanged:)]) {
                    [handler audioProcessTopicConfigManager:self voiceChangerTypeChanged:voiceChangerType];
                }
            }
        });
    });
}

- (float)voiceChangerParam {
    __block float val = 0;
    dispatch_sync(_configOptQueue, ^{
        NSNumber *n = [self.zgUserDefaults objectForKey:ZGAudioProcessTopicConfigVoiceChangerParamKey];
        if (n) {
            val = [n floatValue];
        } else {
            // 设置默认
            val = 0;
        }
    });
    return val;
}

- (void)setVirtualStereoOpen:(BOOL)virtualStereoOpen {
    dispatch_async(_configOptQueue, ^{
        NSNumber *obj = @(virtualStereoOpen);
        [self.zgUserDefaults setObject:obj forKey:ZGAudioProcessTopicConfigVirtualStereoOpenKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<ZGAudioProcessTopicConfigChangedHandler> handler in self.configChangedHandlers) {
                if ([handler respondsToSelector:@selector(audioProcessTopicConfigManager:virtualStereoOpenChanged:)]) {
                    [handler audioProcessTopicConfigManager:self virtualStereoOpenChanged:virtualStereoOpen];
                }
            }
        });
    });
}

- (BOOL)virtualStereoOpen {
    __block BOOL isOpen = NO;
    dispatch_sync(_configOptQueue, ^{
        NSNumber *n = [self.zgUserDefaults objectForKey:ZGAudioProcessTopicConfigVirtualStereoOpenKey];
        if (n) {
            isOpen = [n boolValue];
        } else {
            // 设置默认
            isOpen = NO;
        }
    });
    return isOpen;
}

- (void)setVirtualStereoAngle:(int)angle {
    dispatch_async(_configOptQueue, ^{
        NSNumber *obj = @(angle);
        [self.zgUserDefaults setObject:obj forKey:ZGAudioProcessTopicConfigVirtualStereoAngleKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<ZGAudioProcessTopicConfigChangedHandler> handler in self.configChangedHandlers) {
                if ([handler respondsToSelector:@selector(audioProcessTopicConfigManager:virtualStereoAngleChanged:)]) {
                    [handler audioProcessTopicConfigManager:self virtualStereoAngleChanged:angle];
                }
            }
        });
    });
}

- (int)virtualStereoAngle {
    __block int val = 0;
    dispatch_sync(_configOptQueue, ^{
        NSNumber *n = [self.zgUserDefaults objectForKey:ZGAudioProcessTopicConfigVirtualStereoAngleKey];
        if (n) {
            val = [n intValue];
        } else {
            // 设置默认
            val = 0;
        }
    });
    return val;
}

- (void)setCustomReverbOpen:(BOOL)customReverbOpen {
    _customReverbOpen = customReverbOpen;
    dispatch_async(_configOptQueue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<ZGAudioProcessTopicConfigChangedHandler> handler in self.configChangedHandlers) {
                if ([handler respondsToSelector:@selector(audioProcessTopicConfigManager:customReverbOpen:)]) {
                    [handler audioProcessTopicConfigManager:self customReverbOpen:customReverbOpen];
                }
            }
        });
    });
}

- (void)setReverbOpen:(BOOL)reverbOpen {
    dispatch_async(_configOptQueue, ^{
        NSNumber *obj = @(reverbOpen);
        [self.zgUserDefaults setObject:obj forKey:ZGAudioProcessTopicConfigReverbOpenKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<ZGAudioProcessTopicConfigChangedHandler> handler in self.configChangedHandlers) {
                if ([handler respondsToSelector:@selector(audioProcessTopicConfigManager:reverbOpenChanged:)]) {
                    [handler audioProcessTopicConfigManager:self reverbOpenChanged:reverbOpen];
                }
            }
        });
    });
}

- (BOOL)reverbOpen {
    __block BOOL isOpen = NO;
    dispatch_sync(_configOptQueue, ^{
        NSNumber *n = [self.zgUserDefaults objectForKey:ZGAudioProcessTopicConfigReverbOpenKey];
        if (n) {
            isOpen = [n boolValue];
        } else {
            // 设置默认
            isOpen = NO;
        }
    });
    return isOpen;
}

- (void)setReverbMode:(NSUInteger)reverbMode {
    dispatch_async(_configOptQueue, ^{
        NSNumber *obj = @(reverbMode);
        [self.zgUserDefaults setObject:obj forKey:ZGAudioProcessTopicConfigReverbModeKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<ZGAudioProcessTopicConfigChangedHandler> handler in self.configChangedHandlers) {
                if ([handler respondsToSelector:@selector(audioProcessTopicConfigManager:reverbModeChanged:)]) {
                    [handler audioProcessTopicConfigManager:self reverbModeChanged:reverbMode];
                }
            }
        });
    });
}

- (NSUInteger)reverbMode {
    __block NSUInteger val = NSNotFound;
    dispatch_sync(_configOptQueue, ^{
        NSNumber *n = [self.zgUserDefaults objectForKey:ZGAudioProcessTopicConfigReverbModeKey];
        if (n) {
            val = [n unsignedIntegerValue];
        } else {
            // 设置默认
            val = NSNotFound;
        }
    });
    return val;
}
- (void)setCustomReverbParam:(ZegoAudioAdvancedReverbParam)reverbParam {
    dispatch_async(_configOptQueue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<ZGAudioProcessTopicConfigChangedHandler> handler in self.configChangedHandlers) {
                if ([handler respondsToSelector:@selector(audioProcessTopicConfigManager:customReverbValueChanged:)]) {
                    [handler audioProcessTopicConfigManager:self customReverbValueChanged:reverbParam];
                }
            }
        });
    });
}
@end
#endif
