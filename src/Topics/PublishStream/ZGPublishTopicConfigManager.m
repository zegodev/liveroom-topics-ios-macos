//
//  ZGPublishTopicConfigManager.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/7.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGPublishTopicConfigManager.h"
#import "ZGUserDefaults.h"
#import "ZGHashTableHelper.h"

NSString* const ZGPublishTopicConfigResolutionKey = @"ZGPublishTopicConfigResolutionKey";

NSString* const ZGPublishTopicConfigFpsKey = @"ZGPublishTopicConfigFpsKey";

NSString* const ZGPublishTopicConfigBitrateKey = @"ZGPublishTopicConfigBitrateKey";

NSString* const ZGPublishTopicConfigPreviewViewModeKey = @"ZGPublishTopicConfigPreviewViewModeKey";

NSString* const ZGPublishTopicConfigEnableHardwareEncodeKey = @"ZGPublishTopicConfigEnableHardwareEncodeKey";

NSString* const ZGPublishTopicConfigPreviewMinnorKey = @"ZGPublishTopicConfigPreviewMinnorKey";

@interface ZGPublishTopicConfigManager ()
{
    dispatch_queue_t _configOptQueue;
}

@property (nonatomic) ZGUserDefaults *zgUserDefaults;
@property (nonatomic) NSHashTable *configChangedHandlers;

@end

@implementation ZGPublishTopicConfigManager

static ZGPublishTopicConfigManager *instance = nil;

#pragma mark - public methods

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    return [ZGPublishTopicConfigManager sharedInstance];
}

- (id)copyWithZone:(struct _NSZone *)zone {
    return [ZGPublishTopicConfigManager sharedInstance];
}

- (instancetype)init {
    if (self = [super init]) {
        _zgUserDefaults = [[ZGUserDefaults alloc] init];
        _configChangedHandlers = [ZGHashTableHelper createWeakReferenceHashTable];
        _configOptQueue = dispatch_queue_create("com.doudong.ZGPublishTopicConfigOptQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)addConfigChangedHandler:(id<ZGPublishTopicConfigChangedHandler>)handler {
    if (!handler) return;
    dispatch_async(_configOptQueue, ^{
        if (![self.configChangedHandlers containsObject:handler]) {
            [self.configChangedHandlers addObject:handler];
        }
    });
}

- (void)removeConfigChangedHandler:(id<ZGPublishTopicConfigChangedHandler>)handler {
    if (!handler) return;
    dispatch_async(_configOptQueue, ^{
        [self.configChangedHandlers removeObject:handler];
    });
}

- (void)setResolution:(CGSize)resolution {
    dispatch_async(_configOptQueue, ^{
        NSArray *resObj = @[@(resolution.width), @(resolution.height)];
        [self.zgUserDefaults setObject:resObj forKey:ZGPublishTopicConfigResolutionKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<ZGPublishTopicConfigChangedHandler> handler in self.configChangedHandlers) {
                if ([handler respondsToSelector:@selector(publishTopicConfigManager:resolutionDidChange:)]) {
                    [handler publishTopicConfigManager:self resolutionDidChange:resolution];
                }
            }
        });
    });
}

- (CGSize)resolution {
    __block CGSize rs = CGSizeZero;
    dispatch_sync(_configOptQueue, ^{
        NSArray *r = [self.zgUserDefaults objectForKey:ZGPublishTopicConfigResolutionKey];
        if (r && r.count == 2) {
            rs = CGSizeMake(((NSNumber*)r[0]).integerValue, ((NSNumber*)r[1]).integerValue);
        } else {
            // 设置默认
            rs = CGSizeMake(360, 640);
        }
    });
    return rs;
}

- (void)setFps:(NSInteger)fps {
    dispatch_async(_configOptQueue, ^{
        NSNumber *fpsObj = @(fps);
        [self.zgUserDefaults setObject:fpsObj forKey:ZGPublishTopicConfigFpsKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<ZGPublishTopicConfigChangedHandler> handler in self.configChangedHandlers) {
                if ([handler respondsToSelector:@selector(publishTopicConfigManager:fpsDidChange:)]) {
                    [handler publishTopicConfigManager:self fpsDidChange:fps];
                }
            }
        });
    });
}

- (NSInteger)fps {
    __block NSInteger fps = 0;
    dispatch_sync(_configOptQueue, ^{
        NSNumber *n = [self.zgUserDefaults objectForKey:ZGPublishTopicConfigFpsKey];
        if (n) {
            fps = [n integerValue];
        } else {
            // 设置默认
            fps = 15;
        }
    });
    return fps;
}

- (void)setBitrate:(NSInteger)bitrate {
    dispatch_async(_configOptQueue, ^{
        NSNumber *bitrateObj = @(bitrate);
        [self.zgUserDefaults setObject:bitrateObj forKey:ZGPublishTopicConfigBitrateKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<ZGPublishTopicConfigChangedHandler> handler in self.configChangedHandlers) {
                if ([handler respondsToSelector:@selector(publishTopicConfigManager:bitrateDidChange:)]) {
                    [handler publishTopicConfigManager:self bitrateDidChange:bitrate];
                }
            }
        });
    });
}

- (NSInteger)bitrate {
    __block NSInteger bitrate = 0;
    dispatch_sync(_configOptQueue, ^{
        NSNumber *n = [self.zgUserDefaults objectForKey:ZGPublishTopicConfigBitrateKey];
        if (n) {
            bitrate = [n integerValue];
        } else {
            // 设置默认
            bitrate = 600000;
        }
    });
    return bitrate;
}

- (void)setPreviewViewMode:(ZegoVideoViewMode)previewViewMode {
    dispatch_async(_configOptQueue, ^{
        NSNumber *modeObj = @(previewViewMode);
        [self.zgUserDefaults setObject:modeObj forKey:ZGPublishTopicConfigPreviewViewModeKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<ZGPublishTopicConfigChangedHandler> handler in self.configChangedHandlers) {
                if ([handler respondsToSelector:@selector(publishTopicConfigManager:previewViewModeDidChange:)]) {
                    [handler publishTopicConfigManager:self previewViewModeDidChange:previewViewMode];
                }
            }
        });
    });
}

- (ZegoVideoViewMode)previewViewMode {
    __block ZegoVideoViewMode mode = ZegoVideoViewModeScaleAspectFit;
    dispatch_sync(_configOptQueue, ^{
        NSNumber *n = [self.zgUserDefaults objectForKey:ZGPublishTopicConfigPreviewViewModeKey];
        if (n) {
            mode = (ZegoVideoViewMode)[n integerValue];
        } else {
            // 设置默认
            mode = ZegoVideoViewModeScaleAspectFit;
        }
    });
    return mode;
}

- (void)setEnableHardwareEncode:(BOOL)enableHardwareEncode {
    dispatch_async(_configOptQueue, ^{
        NSNumber *obj = @(enableHardwareEncode);
        [self.zgUserDefaults setObject:obj forKey:ZGPublishTopicConfigEnableHardwareEncodeKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<ZGPublishTopicConfigChangedHandler> handler in self.configChangedHandlers) {
                if ([handler respondsToSelector:@selector(publishTopicConfigManager:enableHardwareEncodeDidChange:)]) {
                    [handler publishTopicConfigManager:self enableHardwareEncodeDidChange:enableHardwareEncode];
                }
            }
        });
    });
}

- (BOOL)isEnableHardwareEncode {
    __block BOOL isEnable = NO;
    dispatch_sync(_configOptQueue, ^{
        NSNumber *n = [self.zgUserDefaults objectForKey:ZGPublishTopicConfigEnableHardwareEncodeKey];
        if (n) {
            isEnable = [n boolValue];
        } else {
            // 设置默认
            isEnable = NO;
        }
    });
    return isEnable;
}

- (void)setPreviewMinnor:(BOOL)isPreviewMinnor {
    dispatch_async(_configOptQueue, ^{
        NSNumber *obj = @(isPreviewMinnor);
        [self.zgUserDefaults setObject:obj forKey:ZGPublishTopicConfigPreviewMinnorKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<ZGPublishTopicConfigChangedHandler> handler in self.configChangedHandlers) {
                if ([handler respondsToSelector:@selector(publishTopicConfigManager:previewMinnorDidChange:)]) {
                    [handler publishTopicConfigManager:self previewMinnorDidChange:isPreviewMinnor];
                }
            }
        });
    });
}

- (BOOL)isPreviewMinnor {
    __block BOOL isEnable = NO;
    dispatch_sync(_configOptQueue, ^{
        NSNumber *n = [self.zgUserDefaults objectForKey:ZGPublishTopicConfigPreviewMinnorKey];
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
