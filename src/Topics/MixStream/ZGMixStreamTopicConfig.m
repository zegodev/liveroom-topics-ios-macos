//
//  ZGMixStreamTopicConfig.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/19.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGMixStreamTopicConfig.h"

@implementation ZGMixStreamTopicConfig

+ (instancetype)configWithDefault {
    ZGMixStreamTopicConfig *conf = [ZGMixStreamTopicConfig new];
    
    conf.outputResolutionWidth = 360;
    conf.isSet_outputResolutionWidth = YES;
    
    conf.outputResolutionHeight = 640;
    conf.isSet_outputResolutionHeight = YES;
    
    conf.outputFps = 15;
    conf.isSet_outputFps = YES;
    
    conf.outputBitrate = 600000;
    conf.isSet_outputBitrate = YES;
    
    conf.channels = 1;
    conf.isSet_channels = YES;
    
    conf.withSoundLevel = YES;
    conf.isSet_withSoundLevel = YES;
    
    return conf;
}

+ (instancetype)fromDictionary:(NSDictionary *)dic {
    if (dic == nil) {
        return nil;
    }
    ZGMixStreamTopicConfig *obj = [ZGMixStreamTopicConfig new];
    
    id orw = dic[NSStringFromSelector(@selector(outputResolutionWidth))];
    if ([self checkIsNSStringOrNSNumber:orw]) {
        obj.outputResolutionWidth = [orw integerValue];
        obj.isSet_outputResolutionWidth = YES;
    }
    
    id orh = dic[NSStringFromSelector(@selector(outputResolutionHeight))];
    if ([self checkIsNSStringOrNSNumber:orh]) {
        obj.outputResolutionHeight = [orh integerValue];
        obj.isSet_outputResolutionHeight = YES;
    }
    
    id oFps = dic[NSStringFromSelector(@selector(outputFps))];
    if ([self checkIsNSStringOrNSNumber:oFps]) {
        obj.outputFps = [oFps integerValue];
        obj.isSet_outputFps = YES;
    }
    
    id oBitrate = dic[NSStringFromSelector(@selector(outputBitrate))];
    if ([self checkIsNSStringOrNSNumber:oBitrate]) {
        obj.outputBitrate = [oBitrate integerValue];
        obj.isSet_outputBitrate = YES;
    }
    
    id channels = dic[NSStringFromSelector(@selector(channels))];
    if ([self checkIsNSStringOrNSNumber:channels]) {
        obj.channels = [oFps integerValue];
        obj.isSet_channels = YES;
    }
    
    id wsl = dic[NSStringFromSelector(@selector(withSoundLevel))];
    if ([self checkIsNSStringOrNSNumber:wsl]) {
        obj.withSoundLevel = [wsl integerValue];
        obj.isSet_withSoundLevel = YES;
    }
    
    return obj;
}

- (NSDictionary *)toDictionaryKeyedByIsSet:(BOOL)keyedByIsSet {
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    
    BOOL mapORW = YES,
         mapORH = YES,
         mapOFps = YES,
         mapOBitrate = YES,
         mapChannels = YES,
         mapWSL = YES;
    
    if (keyedByIsSet) {
        mapORW = self.isSet_outputResolutionWidth;
        mapORH = self.isSet_outputResolutionHeight;
        mapOFps = self.isSet_outputFps;
        mapOBitrate = self.isSet_outputBitrate;
        mapChannels = self.isSet_channels;
        mapWSL = self.isSet_withSoundLevel;
    }
    
    if (mapORW) {
        dic[NSStringFromSelector(@selector(outputResolutionWidth))] = @( self.outputResolutionWidth);
    }
    if (mapORH) {
        dic[NSStringFromSelector(@selector(outputResolutionHeight))] = @(self.outputResolutionHeight);
    }
    if (mapOFps) {
        dic[NSStringFromSelector(@selector(outputFps))] = @(self.outputFps);
    }
    if (mapOBitrate) {
        dic[NSStringFromSelector(@selector(outputBitrate))] = @(self.outputBitrate);
    }
    if (mapChannels) {
        dic[NSStringFromSelector(@selector(channels))] = @(self.channels);
    }
    if (mapWSL) {
        dic[NSStringFromSelector(@selector(withSoundLevel))] = @(self.withSoundLevel);
    }
    
    return [dic copy];
}

+ (BOOL)checkIsNSStringOrNSNumber:(id)obj {
    return ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSNumber class]]);
}

@end
