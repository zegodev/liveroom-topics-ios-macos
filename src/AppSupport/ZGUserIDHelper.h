//
//  ZGUserIDHelper.h
//  LiveRoomPlayground
//
//  Copyright © 2018年 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZGUserIDHelper : NSObject

/**
 会返回一个全局的 userID。如果不存在，则随机生成一个然后保存在 userDefaults 中。
 */
@property (class, copy ,nonatomic, readonly) NSString *userID;

+ (NSString *)getDeviceUUID;

@end

NS_ASSUME_NONNULL_END
