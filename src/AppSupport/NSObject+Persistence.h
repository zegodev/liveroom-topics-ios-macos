//
//  NSObject+Persistence.h
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/4/17.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (Persistence)

- (nullable id)savedValueForKey:(NSString *)key;
- (void)saveValue:(nullable id)value forKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
