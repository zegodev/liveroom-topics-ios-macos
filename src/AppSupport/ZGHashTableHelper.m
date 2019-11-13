//
//  ZGHashTableHelper.m
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/8/9.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGHashTableHelper.h"

@implementation ZGHashTableHelper

+ (NSHashTable *)createWeakReferenceHashTable {
    NSHashTable *hashTable = [NSHashTable alloc];
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
    hashTable = [hashTable initWithOptions:NSPointerFunctionsWeakMemory|NSPointerFunctionsObjectPointerPersonality capacity:0];
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
    if ([NSHashTable respondsToSelector:@selector(weakObjectsHashTable)]) {
        hashTable = [hashTable initWithOptions:NSPointerFunctionsWeakMemory|NSPointerFunctionsObjectPointerPersonality capacity:0];
    } else {
        // silence deprecated warnings
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        hashTable = [hashTable initWithOptions:NSPointerFunctionsZeroingWeakMemory|NSPointerFunctionsObjectPointerPersonality capacity:0];
#pragma clang diagnostic pop
    }
    
#endif
    
    return hashTable;
}

@end
