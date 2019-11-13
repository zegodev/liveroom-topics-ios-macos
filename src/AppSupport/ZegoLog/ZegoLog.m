//
//  ZegoLogger.m
//  QueuingServices-iOS
//
//  Created by Sky on 2018/12/26.
//  Copyright © 2018 zego. All rights reserved.
//

#import "ZegoLog.h"
#if TARGET_OS_OSX
#import <Cocoa/Cocoa.h>
#elif TARGET_OS_IOS
#import <UIKit/UIKit.h>
#endif
#import <pthread.h>
#import <dispatch/dispatch.h>
#import "ZegoDefaultLogFormatter.h"

#ifndef ZEGO_LOG_MAX_QUEUE_SIZE
#define ZEGO_LOG_MAX_QUEUE_SIZE 100
#endif

NSMutableArray<id<ZegoLogger>> *_loggers = nil;
dispatch_semaphore_t _queueSemaphore;

@implementation ZegoLog

+ (void)initialize {
    _loggers = [NSMutableArray array];
    _queueSemaphore = dispatch_semaphore_create(ZEGO_LOG_MAX_QUEUE_SIZE);
    
    NSString *notiName;
#if TARGET_OS_OSX
    notiName = NSApplicationWillTerminateNotification;
#elif TARGET_OS_IOS
    notiName = UIApplicationWillTerminateNotification;
#endif
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(onApplicationWillTerminate)
                                               name:notiName
                                             object:nil];
}

+ (NSArray<id<ZegoLogger>> *)allLoggers {
    return _loggers.copy;
}

+ (void)addLogger:(id<ZegoLogger>)logger {
    [self addLogger:logger level:kZegoLogLevelVerbose];
}

+ (void)addLogger:(id<ZegoLogger>)logger level:(ZegoLogLevel)level {
    BOOL isLoggerExist = [_loggers indexOfObject:logger] != NSNotFound;
    if (isLoggerExist) {
        return;
    }
    
    [_loggers addObject:logger];
    
    if ([logger respondsToSelector:@selector(didAddLogger)]) {
        [logger didAddLogger];
    }
}

+ (void)removeLogger:(id<ZegoLogger>)logger {
    if ([logger respondsToSelector:@selector(willRemoveLogger)]) {
        [logger willRemoveLogger];
    }
    
    [_loggers removeObject:logger];
}

+ (void)removeAllLoggers {
    for (id<ZegoLogger> logger in _loggers) {
        if ([logger respondsToSelector:@selector(willRemoveLogger)]) {
            [logger willRemoveLogger];
        }
    }
    
    [_loggers removeAllObjects];
}


+ (void)logMessage:(ZegoLogMessage *)message {
    if (message.message) {
        [self zg_logMessage:message];
    }
}

+ (void)logWithFlag:(ZegoLogFlag)flag
               file:(const char *)file
           function:(const char *)function
               line:(NSUInteger)line
             format:(NSString *)format, ... NS_FORMAT_FUNCTION(5,6) {
    if (format) {
        va_list args;
        va_start(args, format);
        [self logWithFlag:flag
                     file:file
                 function:function
                     line:line
                   format:format
                     args:args];
        va_end(args);
    }
}

+ (void)logWithFlag:(ZegoLogFlag)flag
               file:(const char *)file
           function:(const char *)function
               line:(NSUInteger)line
             format:(NSString *)format
               args:(va_list)argList {
    if (!format) {
        return;
    }
    
    NSString *msg = [[NSString alloc] initWithFormat:format arguments:argList];
    ZegoLogMessage *message = [ZegoLogMessage messageWithMessage:msg
                                                            flag:flag
                                                        fileName:[NSString stringWithUTF8String:file]
                                                        function:[NSString stringWithUTF8String:function]
                                                            line:line];
    
    [self logMessage:message];
}

+ (void)zg_logMessage:(ZegoLogMessage *)message {
    for (id<ZegoLogger> logger in _loggers) {
        if (logger.level & message.flag) {        
            [logger logMessage:message];
        }
    }
}

+ (void)flushLog {
    for (id<ZegoLogger> logger in _loggers) {
        [logger flush];
    }
}

+ (void)onApplicationWillTerminate {
    [self flushLog];
}

@end



#pragma mark - Loggers

@implementation ZegoAbstructLogger

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (instancetype)init {
    if (self = [super init]) {
        _level = kZegoLogLevelVerbose;
        _formatter = [ZegoDefaultLogFormatter new];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleMemoryWarning) name:@"UIApplicationDidReceiveMemoryWarningNotification" object:nil];
    }
    return self;
}

- (void)logMessage:(ZegoLogMessage *)message {
    if (self.logQueue) {
        dispatch_async(self.logQueue, ^{
            dispatch_semaphore_wait(_queueSemaphore, DISPATCH_TIME_FOREVER);
            @autoreleasepool {
                [self zg_logMessage:message];
            }
        });
    }
    else {
        @autoreleasepool {
            [self zg_logMessage:message];
        }
    }
}

- (void)flush {
    if (self.logQueue) {
        dispatch_async(self.logQueue, ^{
            dispatch_semaphore_wait(_queueSemaphore, DISPATCH_TIME_FOREVER);
            @autoreleasepool {
                [self zg_flush];
            }
        });
    }
    else {
        @autoreleasepool {
            [self zg_flush];
        }
    }
}

- (void)zg_logMessage:(ZegoLogMessage *)message {
    NSAssert(NO, @"YOU SHOULD OVER WRITE THIS METHOD IN SUBCLASS");
}

- (void)zg_flush {
    NSAssert(NO, @"YOU SHOULD OVER WRITE THIS METHOD IN SUBCLASS");
}

- (void)handleMemoryWarning {
    [self flush];
}

- (void)setFormatter:(id<ZegoLogFormatter>)formatter {
    if (formatter == nil) {
        formatter = [ZegoDefaultLogFormatter new];
    }
    
    _formatter = formatter;
}


@end
