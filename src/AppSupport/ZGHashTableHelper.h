//
//  ZGHashTableHelper.h
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/8/9.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZGHashTableHelper : NSObject

+ (NSHashTable *)createWeakReferenceHashTable;

@end

NS_ASSUME_NONNULL_END
