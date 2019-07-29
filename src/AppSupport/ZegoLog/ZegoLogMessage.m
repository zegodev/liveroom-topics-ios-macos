//
//  ZegoLogMessage.m
//  Chatroom-iOS
//
//  Created by Sky on 2019/3/26.
//  Copyright © 2019 zego. All rights reserved.
//

#import "ZegoLogMessage.h"
#import <pthread.h>

@interface ZegoLogMessage ()

@property (assign, nonatomic) NSUInteger msgID;
@property (copy, nonatomic) NSString *message;
@property (assign, nonatomic) ZegoLogFlag flag;
@property (copy, nonatomic) NSString *fileName;
@property (copy, nonatomic) NSString *function;
@property (assign, nonatomic) NSUInteger line;
@property (strong, nonatomic) NSDate *date;
@property (copy, nonatomic) NSString *threadID;
@property (copy, nonatomic) NSString *threadName;
@property (copy, nonatomic) NSString *queueLabel;

@end


@implementation ZegoLogMessage

+ (instancetype)messageWithMessage:(NSString *)message
                              flag:(ZegoLogFlag)flag
                          fileName:(NSString *)fileName
                          function:(NSString *)function
                              line:(NSUInteger)line {
    static NSUInteger msgID = 0;
    
    ZegoLogMessage *instance = [self new];
    instance.msgID = msgID++;
    instance.message = message;
    instance.flag = flag;
    instance.fileName = fileName;
    instance.function = function;
    instance.line = line;
    instance.date = NSDate.date;
    
    __uint64_t tid;
    if (pthread_threadid_np(NULL, &tid) == 0) {
        instance.threadID = [[NSString alloc] initWithFormat:@"%llu", tid];
    } else {
        instance.threadID = @"missing threadId";
    }
    instance.threadName   = NSThread.currentThread.name;
    instance.queueLabel = [NSString stringWithUTF8String:dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL)];
    
    return instance;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    ZegoLogMessage *instance = [self.class new];
    instance.msgID = _msgID;
    instance.message = _message;
    instance.flag = _flag;
    instance.fileName = _fileName;
    instance.function = _function;
    instance.line = _line;
    instance.date = _date.copy;
    instance.threadID = _threadID;
    instance.threadName = _threadName;
    instance.queueLabel = _queueLabel;
    
    return instance;
}

@end
