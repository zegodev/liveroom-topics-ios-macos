//
//  NSObject+Persistence.m
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/4/17.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "NSObject+Persistence.h"

@implementation NSObject (Persistence)

- (nullable id)savedValueForKey:(NSString *)key {
    NSDictionary *classKVMap = [NSUserDefaults.standardUserDefaults objectForKey:NSStringFromClass(self.class)];
    
    if (!classKVMap) {
        return nil;
    }
    
    id value = classKVMap[key];
    
    if (!value || [value isKindOfClass:NSNull.class]) {
        return nil;
    }
    
    return value;
}

- (void)saveValue:(nullable id)value forKey:(NSString *)key {
    NSDictionary *classKVMap = [NSUserDefaults.standardUserDefaults objectForKey:NSStringFromClass(self.class)];
    NSMutableDictionary *mutiClassKVMap = nil;
    
    if (classKVMap) {
        mutiClassKVMap = [NSMutableDictionary dictionaryWithDictionary:classKVMap];
    }
    else {
        mutiClassKVMap = [NSMutableDictionary dictionary];
    }
    
    mutiClassKVMap[key] = value;
    
    [NSUserDefaults.standardUserDefaults setObject:mutiClassKVMap forKey:NSStringFromClass(self.class)];
    [NSUserDefaults.standardUserDefaults synchronize];
}

@end
