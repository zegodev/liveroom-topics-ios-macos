//
//  ZGMixStreamTopicConfigManager.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/23.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGMixStreamTopicConfigManager.h"
#import "ZGUserDefaults.h"
#import "ZGJsonHelper.h"
#import "ZGHashTableHelper.h"

NSString* const ZGMixStreamTopicConfigKey = @"kZGMixStreamTopicConfig";

@interface ZGMixStreamTopicConfigManager ()
{
    dispatch_queue_t _configOptQueue;
}

@property (nonatomic) ZGUserDefaults *zgUserDefaults;
@property (nonatomic, copy) NSString *cachedConfigStr;

@property (nonatomic) NSHashTable *configUpdatedHandles;

@end

@implementation ZGMixStreamTopicConfigManager

static ZGMixStreamTopicConfigManager *instance = nil;

#pragma mark - public methods

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    return [ZGMixStreamTopicConfigManager sharedInstance];
}

- (id)copyWithZone:(struct _NSZone *)zone {
    return [ZGMixStreamTopicConfigManager sharedInstance];
}

- (instancetype)init {
    if (self = [super init]) {
        _configOptQueue = dispatch_queue_create("com.doudong.ZGMixStreamTopicConfigOptQueue", DISPATCH_QUEUE_SERIAL);
        _zgUserDefaults = [[ZGUserDefaults alloc] init];
        _configUpdatedHandles = [ZGHashTableHelper createWeakReferenceHashTable];
    }
    return self;
}

+ (ZGMixStreamTopicConfig *)defaultConfig {
    ZGMixStreamTopicConfig *conf = [ZGMixStreamTopicConfig new];
    
    conf.outputResolutionWidth = 360;
    conf.outputResolutionHeight = 640;
    conf.outputFps = 15;
    conf.outputBitrate = 600000;
    conf.channels = 1;
    conf.withSoundLevel = YES;
    
    return conf;
}

- (void)setConfig:(ZGMixStreamTopicConfig *)confObj {
    dispatch_async(_configOptQueue, ^{
        // confObj 为 nil 时，删除设置
        if (confObj == nil) {
            [self.zgUserDefaults removeObjectForKey:ZGMixStreamTopicConfigKey];
            [self.zgUserDefaults synchronize];
            self.cachedConfigStr = nil;
            [self notifyConfigUpdated:nil];
            return;
        }
        
        NSDictionary *confDic = [confObj toDictionary];
        NSString *configStr = [ZGJsonHelper encodeToJSON:confDic];
        if (configStr) {
            self.cachedConfigStr = configStr;
            [self.zgUserDefaults setObject:configStr forKey:ZGMixStreamTopicConfigKey];
            [self.zgUserDefaults synchronize];
            [self notifyConfigUpdated:confObj];
        }
    });
}

- (ZGMixStreamTopicConfig *)config {
    __block ZGMixStreamTopicConfig *conf = nil;
    dispatch_sync(_configOptQueue, ^{
        NSString *configStr = self.cachedConfigStr;
        if (configStr == nil || configStr.length == 0) {
            configStr = [self.zgUserDefaults stringForKey:ZGMixStreamTopicConfigKey];
        }
        
        ZGMixStreamTopicConfig *confObj = nil;
        NSDictionary *confDic = [ZGJsonHelper decodeFromJSON:configStr];
        if ([confDic isKindOfClass:[NSDictionary class]]) {
            confObj = [ZGMixStreamTopicConfig fromDictionary:confDic];
        }
        
        // 不存在或获取失败，则返回默认配置
        if (!confObj) {
            confObj = [[self class] defaultConfig];
        }
        conf = confObj;
    });
    return conf;
}

- (void)addConfigUpdatedHandler:(id<ZGMixStreamTopicConfigUpdatedHandler>)handler {
    if (!handler) return;
    if (![self.configUpdatedHandles containsObject:handler]) {
        [self.configUpdatedHandles addObject:handler];
    }
}

- (void)removeConfigUpdatedHandler:(id<ZGMixStreamTopicConfigUpdatedHandler>)handler {
    if (!handler) return;
    [self.configUpdatedHandles removeObject:handler];
}

#pragma mark - private methods


- (void)notifyConfigUpdated:(ZGMixStreamTopicConfig *)config {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id handler in self.configUpdatedHandles) {
            if ([handler conformsToProtocol:@protocol(ZGMixStreamTopicConfigUpdatedHandler)]
                && [handler respondsToSelector:@selector(configManager:mixStreamTopicConfigUpdated:)]) {
                [handler configManager:self mixStreamTopicConfigUpdated:config];
            }
        }
    });
}

@end
