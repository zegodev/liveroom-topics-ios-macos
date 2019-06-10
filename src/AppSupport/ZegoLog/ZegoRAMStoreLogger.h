//
//  ZegoRAMStoreLogger.h
//  Chatroom-iOS
//
//  Created by Sky on 2019/3/26.
//  Copyright © 2019 zego. All rights reserved.
//

#import "ZegoLog.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *ZegoRAMStoreLoggerLogDidChangeNotification;


@interface ZegoRAMStoreLogger : ZegoAbstructLogger

@property (strong, atomic, readonly) NSArray<ZegoLogMessage*>* logs;

@end

NS_ASSUME_NONNULL_END
