//
//  NSObject+Binding.h
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/5/10.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KVOController.h"

NS_ASSUME_NONNULL_BEGIN

#define ZGBindKeyPath(KEYPATH) FBKVOKeyPath(KEYPATH)

@interface NSObject (Binding)

- (void)bind:(NSObject *)obj keyPath:(NSString *)keyPath callback:(void(^)(id _Nullable value))callback;
- (void)bind:(NSObject *)obj keyPath:(NSString *)keyPath action:(SEL)action;

@end

NS_ASSUME_NONNULL_END
