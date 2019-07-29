//
//  ZegoDiskLogger.h
//  Chatroom-iOS
//
//  Created by Sky on 2019/3/26.
//  Copyright © 2019 zego. All rights reserved.
//

#import "ZegoLog.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZegoDiskLogger : ZegoAbstructLogger

+ (instancetype)loggerWithStoragePath:(nullable NSString *)path;
- (instancetype)initWithStoragePath:(nullable NSString *)path;

@end

NS_ASSUME_NONNULL_END
