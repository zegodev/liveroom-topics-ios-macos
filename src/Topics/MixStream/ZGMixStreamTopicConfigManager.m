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

NSString const* ZGMixStreamTopicConfigKey = @"kZGMixStreamTopicConfig";

@interface ZGMixStreamTopicConfigManager ()

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

+(id) allocWithZone:(struct _NSZone *)zone {
    return [ZGMixStreamTopicConfigManager sharedInstance];
}

-(id) copyWithZone:(struct _NSZone *)zone {
    return [ZGMixStreamTopicConfigManager sharedInstance];
}

- (instancetype)init {
    if (self = [super init]) {
        _zgUserDefaults = [[ZGUserDefaults alloc] init];
        _configUpdatedHandles = [[NSHashTable alloc] init];
    }
    return self;
}

- (ZGMixStreamTopicConfig *)loadConfig {
    NSString *configStr = self.cachedConfigStr;
    if (configStr == nil || configStr.length == 0) {
        configStr = [self.zgUserDefaults stringForKey:ZGMixStreamTopicConfigKey];
    }
    
    NSDictionary *confDic = [ZGJsonHelper decodeFromJSON:configStr];
    if (![confDic isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    ZGMixStreamTopicConfig *confObj = [ZGMixStreamTopicConfig fromDictionary:confDic];
    return confObj;
}

- (void)updateConfig:(ZGMixStreamTopicConfig *)confObj {
    // confObj 为 nil 时，删除设置
    if (confObj == nil) {
        [self.zgUserDefaults removeObjectForKey:ZGMixStreamTopicConfigKey];
        [self.zgUserDefaults synchronize];
        self.cachedConfigStr = nil;
        [self notifyConfigUpdated:nil];
        return;
    }
    
    NSDictionary *confDic = [confObj toDictionaryKeyedByIsSet:YES];
    NSString *configStr = [ZGJsonHelper encodeToJSON:confDic];
    if (configStr) {
        self.cachedConfigStr = configStr;
        [self.zgUserDefaults setObject:configStr forKey:ZGMixStreamTopicConfigKey];
        [self.zgUserDefaults synchronize];
        [self notifyConfigUpdated:confObj];
    }
}

- (void)addConfigUpdatedHandler:(id<ZGMixStreamTopicConfigUpdatedHandler>)handler {
    [self.configUpdatedHandles addObject:handler];
}

- (void)removeConfigUpdatedHandler:(id<ZGMixStreamTopicConfigUpdatedHandler>)handler {
    [self.configUpdatedHandles removeObject:handler];
}

#pragma mark - private methods


- (void)notifyConfigUpdated:(ZGMixStreamTopicConfig *)config {
    for (id handler in self.configUpdatedHandles) {
        if ([handler conformsToProtocol:@protocol(ZGMixStreamTopicConfigUpdatedHandler)]
            && [handler respondsToSelector:@selector(configManager:mixStreamTopicConfigUpdated:)]) {
            [handler configManager:self mixStreamTopicConfigUpdated:config];
        }
    }
}

@end
