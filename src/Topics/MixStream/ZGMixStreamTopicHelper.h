//
//  ZGMixStreamTopicHelper.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/23.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZGMixStreamTopicHelper : NSObject


/**
 获取当前时间戳

 @return 当前时间戳
 */
+ (unsigned int)getCurrentTimestamp;


/**
 将时间戳组合为 zego userID

 @param timestamp 时间戳
 @return user ID
 */
+ (NSString *)assembleUserIDWithTimestamp:(unsigned int)timestamp;

/**
 解析 zego userID，获取到时间戳

 @param userID zego userID
 @param occurError 返回是否发生错误
 @return 时间戳信息
 */
+ (unsigned int)parseTimestampFromUserID:(NSString *)userID occurError:(BOOL *)occurError;

@end

NS_ASSUME_NONNULL_END
