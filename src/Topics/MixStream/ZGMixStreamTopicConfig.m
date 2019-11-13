//
//  ZGMixStreamTopicConfig.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/19.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGMixStreamTopicConfig.h"

@implementation ZGMixStreamTopicConfig

+ (instancetype)fromDictionary:(NSDictionary *)dic {
    if (dic == nil) {
        return nil;
    }
    ZGMixStreamTopicConfig *obj = [ZGMixStreamTopicConfig new];
    
    id orw = dic[NSStringFromSelector(@selector(outputResolutionWidth))];
    if ([self checkIsNSStringOrNSNumber:orw]) {
        obj.outputResolutionWidth = [orw integerValue];
    }
    
    id orh = dic[NSStringFromSelector(@selector(outputResolutionHeight))];
    if ([self checkIsNSStringOrNSNumber:orh]) {
        obj.outputResolutionHeight = [orh integerValue];
    }
    
    id oFps = dic[NSStringFromSelector(@selector(outputFps))];
    if ([self checkIsNSStringOrNSNumber:oFps]) {
        obj.outputFps = [oFps integerValue];
    }
    
    id oBitrate = dic[NSStringFromSelector(@selector(outputBitrate))];
    if ([self checkIsNSStringOrNSNumber:oBitrate]) {
        obj.outputBitrate = [oBitrate integerValue];
    }
    
    id channels = dic[NSStringFromSelector(@selector(channels))];
    if ([self checkIsNSStringOrNSNumber:channels]) {
        obj.channels = [oFps integerValue];
    }
    
    id wsl = dic[NSStringFromSelector(@selector(withSoundLevel))];
    if ([self checkIsNSStringOrNSNumber:wsl]) {
        obj.withSoundLevel = [wsl integerValue];
    }
    
    return obj;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    
    dic[NSStringFromSelector(@selector(outputResolutionWidth))] = @( self.outputResolutionWidth);
    
    dic[NSStringFromSelector(@selector(outputResolutionHeight))] = @(self.outputResolutionHeight);
    
    dic[NSStringFromSelector(@selector(outputFps))] = @(self.outputFps);
    
    dic[NSStringFromSelector(@selector(outputBitrate))] = @(self.outputBitrate);
    
    dic[NSStringFromSelector(@selector(channels))] = @(self.channels);
    
    dic[NSStringFromSelector(@selector(withSoundLevel))] = @(self.withSoundLevel);
    
    return [dic copy];
}

+ (BOOL)checkIsNSStringOrNSNumber:(id)obj {
    return ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSNumber class]]);
}

@end
