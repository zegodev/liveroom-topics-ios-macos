//
//  ZGAppGlobalConfig.m
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/8/6.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGAppGlobalConfig.h"

@implementation ZGAppGlobalConfig

+ (instancetype)fromDictionary:(NSDictionary *)dic {
    if (dic == nil) {
        return nil;
    }
    ZGAppGlobalConfig *obj = [[ZGAppGlobalConfig alloc] init];
    
    id appID = dic[NSStringFromSelector(@selector(appID))];
    if ([appID isKindOfClass:[NSNumber class]]) {
        obj.appID = [appID unsignedIntValue];
    } else if ([appID isKindOfClass:[NSString class]]) {
        obj.appID = (unsigned int)[appID longLongValue];
    }
    
    id appSign = dic[NSStringFromSelector(@selector(appSign))];
    if ([appSign isKindOfClass:[NSString class]]) {
        obj.appSign = appSign;
    }
    
    id env = dic[NSStringFromSelector(@selector(environment))];
    if ([self checkIsNSStringOrNSNumber:env]) {
        obj.environment = [env integerValue];
    }
    
    return obj;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    
    dic[NSStringFromSelector(@selector(appID))] = @(self.appID);
    dic[NSStringFromSelector(@selector(appSign))] = self.appSign?self.appSign:@"";
    dic[NSStringFromSelector(@selector(environment))] = @(self.environment);
    
    return [dic copy];
}

+ (BOOL)checkIsNSStringOrNSNumber:(id)obj {
    return ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSNumber class]]);
}

@end
