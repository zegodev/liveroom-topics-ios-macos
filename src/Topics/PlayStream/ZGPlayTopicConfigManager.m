//
//  ZGPlayTopicConfigManager.m
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/8/12.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGPlayTopicConfigManager.h"
#import "ZGUserDefaults.h"
#import "ZGHashTableHelper.h"

NSString* const ZGPlayTopicConfigPlayViewModeKey = @"ZGPlayTopicConfigPlayViewModeKey";

NSString* const ZGPlayTopicConfigPlayStreamVolumeKey = @"ZGPlayTopicConfigPlayStreamVolumeKey";

NSString* const ZGPlayTopicConfigEnableHardwareDecodeKey = @"ZGPlayTopicConfigEnableHardwareDecodeKey";
NSString* const ZGPlayTopicConfigPreviewMinnorKey = @"ZGPlayTopicConfigPreviewMinnorKey";

@interface ZGPlayTopicConfigManager ()
{
    dispatch_queue_t _configOptQueue;
}

@property (nonatomic) ZGUserDefaults *zgUserDefaults;
@property (nonatomic) NSHashTable *configChangedHandlers;

@end

@implementation ZGPlayTopicConfigManager

static ZGPlayTopicConfigManager *instance = nil;

#pragma mark - public methods

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    return [ZGPlayTopicConfigManager sharedInstance];
}

- (id)copyWithZone:(struct _NSZone *)zone {
    return [ZGPlayTopicConfigManager sharedInstance];
}

- (instancetype)init {
    if (self = [super init]) {
        _zgUserDefaults = [[ZGUserDefaults alloc] init];
        _configChangedHandlers = [ZGHashTableHelper createWeakReferenceHashTable];
        _configOptQueue = dispatch_queue_create("com.doudong.ZGPlayTopicConfigOptQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)addConfigChangedHandler:(id<ZGPlayTopicConfigChangedHandler>)handler {
    if (!handler) return;
    dispatch_async(_configOptQueue, ^{
        if (![self.configChangedHandlers containsObject:handler]) {
            [self.configChangedHandlers addObject:handler];
        }
    });
}

- (void)removeConfigChangedHandler:(id<ZGPlayTopicConfigChangedHandler>)handler {
    if (!handler) return;
    dispatch_async(_configOptQueue, ^{
        [self.configChangedHandlers removeObject:handler];
    });
}

- (void)setPlayViewMode:(ZegoVideoViewMode)playViewMode {
    dispatch_async(_configOptQueue, ^{
        NSNumber *obj = @(playViewMode);
        [self.zgUserDefaults setObject:obj forKey:ZGPlayTopicConfigPlayViewModeKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<ZGPlayTopicConfigChangedHandler> handler in self.configChangedHandlers) {
                if ([handler respondsToSelector:@selector(playTopicConfigManager:playViewModeDidChange:)]) {
                    [handler playTopicConfigManager:self playViewModeDidChange:playViewMode];
                }
            }
        });
    });
}

- (ZegoVideoViewMode)playViewMode {
    __block ZegoVideoViewMode viewMode = ZegoVideoViewModeScaleAspectFit;
    dispatch_sync(_configOptQueue, ^{
        NSNumber *obj = [self.zgUserDefaults objectForKey:ZGPlayTopicConfigPlayViewModeKey];
        if (obj) {
            viewMode = (ZegoVideoViewMode)[obj integerValue];
        } else {
            viewMode = ZegoVideoViewModeScaleAspectFit;
        }
    });
    return viewMode;
}

- (void)setPlayStreamVolume:(int)playStreamVolume {
    dispatch_async(_configOptQueue, ^{
        NSNumber *obj = @(playStreamVolume);
        [self.zgUserDefaults setObject:obj forKey:ZGPlayTopicConfigPlayStreamVolumeKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<ZGPlayTopicConfigChangedHandler> handler in self.configChangedHandlers) {
                if ([handler respondsToSelector:@selector(playTopicConfigManager:playStreamVolumeDidChange:)]) {
                    [handler playTopicConfigManager:self playStreamVolumeDidChange:playStreamVolume];
                }
            }
        });
    });
}

- (int)playStreamVolume {
    __block int volume = 0;
    dispatch_sync(_configOptQueue, ^{
        NSNumber *obj = [self.zgUserDefaults objectForKey:ZGPlayTopicConfigPlayStreamVolumeKey];
        if (obj) {
            volume = [obj intValue];
        } else {
            volume = 100;
        }
    });
    return volume;
}

- (void)setEnableHardwareDecode:(BOOL)enableHardwareDecode {
    dispatch_async(_configOptQueue, ^{
        NSNumber *obj = @(enableHardwareDecode);
        [self.zgUserDefaults setObject:obj forKey:ZGPlayTopicConfigEnableHardwareDecodeKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<ZGPlayTopicConfigChangedHandler> handler in self.configChangedHandlers) {
                if ([handler respondsToSelector:@selector(playTopicConfigManager:enableHardwareDecodeDidChange:)]) {
                    [handler playTopicConfigManager:self enableHardwareDecodeDidChange:enableHardwareDecode];
                }
            }
        });
    });
}

- (BOOL)isEnableHardwareDecode {
    __block BOOL isEnable = NO;
    dispatch_sync(_configOptQueue, ^{
        NSNumber *obj = [self.zgUserDefaults objectForKey:ZGPlayTopicConfigEnableHardwareDecodeKey];
        if (obj) {
            isEnable = [obj boolValue];
        } else {
            isEnable = NO;
        }
    });
    return isEnable;
}

- (void)setPreviewMinnor:(BOOL)isPreviewMinnor {
    dispatch_async(_configOptQueue, ^{
        NSNumber *obj = @(isPreviewMinnor);
        [self.zgUserDefaults setObject:obj forKey:ZGPlayTopicConfigPreviewMinnorKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<ZGPlayTopicConfigChangedHandler> handler in self.configChangedHandlers) {
                if ([handler respondsToSelector:@selector(playTopicConfigManager:previewMinnorDidChange:)]) {
                    [handler playTopicConfigManager:self previewMinnorDidChange:isPreviewMinnor];
                }
            }
        });
    });
}

- (BOOL)isPreviewMinnor {
    __block BOOL isEnable = NO;
    dispatch_sync(_configOptQueue, ^{
        NSNumber *n = [self.zgUserDefaults objectForKey:ZGPlayTopicConfigPreviewMinnorKey];
        if (n) {
            isEnable = [n boolValue];
        } else {
            // 设置默认
            isEnable = YES;
        }
    });
    return isEnable;
}

@end
