//
//  NSObject+Binding.m
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/5/10.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "NSObject+Binding.h"

@implementation NSObject (Binding)

- (void)bind:(NSObject *)obj keyPath:(NSString *)keyPath callback:(void (^)(id _Nonnull value))callback {
    [self.KVOController observe:obj keyPath:keyPath options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew) block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSKeyValueChangeKey,id> * _Nonnull change) {
        id value = change[NSKeyValueChangeNewKey];
        
        if ([value isKindOfClass:NSNull.class]) {
            value = nil;
        }
        
        callback(value);
    }];
}

- (void)bind:(NSObject *)obj keyPath:(NSString *)keyPath action:(SEL)action {
    [self.KVOController observe:obj keyPath:keyPath options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew) action:action];
}

@end
