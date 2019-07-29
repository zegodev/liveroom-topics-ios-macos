//
//  ZegoLogMessage.h
//  Chatroom-iOS
//
//  Created by Sky on 2019/3/26.
//  Copyright © 2019 zego. All rights reserved.
//

#import "ZegoLog-Defines.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZegoLogMessage : NSObject <NSCopying>

@property (assign, nonatomic, readonly) NSUInteger msgID;
@property (copy, nonatomic, readonly) NSString *message;
@property (assign, nonatomic, readonly) ZegoLogFlag flag;
@property (copy, nonatomic, readonly) NSString *fileName;
@property (copy, nonatomic, readonly) NSString *function;
@property (assign, nonatomic, readonly) NSUInteger line;
@property (strong, nonatomic, readonly) NSDate *date;
@property (copy, nonatomic, readonly) NSString *threadID;
@property (copy, nonatomic, readonly) NSString *threadName;
@property (copy, nonatomic, readonly) NSString *queueLabel;

+ (instancetype)messageWithMessage:(NSString *)message
                              flag:(ZegoLogFlag)flag
                          fileName:(NSString *)fileName
                          function:(NSString *)function
                              line:(NSUInteger)line;

@end

NS_ASSUME_NONNULL_END
