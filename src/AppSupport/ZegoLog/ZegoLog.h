//
//  ZegoLogger.h
//  QueuingServices-iOS
//
//  Created by Sky on 2018/12/26.
//  Copyright © 2018 zego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZegoLog-Defines.h"
#import "ZegoLogMessage.h"


NS_ASSUME_NONNULL_BEGIN

@interface ZegoLog : NSObject

@property (class, strong, nonatomic, readonly) NSArray<id<ZegoLogger>> *allLoggers;

+ (void)addLogger:(id<ZegoLogger>)logger;
+ (void)addLogger:(id<ZegoLogger>)logger level:(ZegoLogLevel)level;
+ (void)removeLogger:(id<ZegoLogger>)logger;
+ (void)removeAllLoggers;


+ (void)logMessage:(ZegoLogMessage *)message;

+ (void)logWithFlag:(ZegoLogFlag)flag
               file:(const char *)file
           function:(const char *)function
               line:(NSUInteger)line
             format:(NSString *)format, ... NS_FORMAT_FUNCTION(5,6);

+ (void)logWithFlag:(ZegoLogFlag)flag
               file:(const char *)file
           function:(const char *)function
               line:(NSUInteger)line
             format:(NSString *)format
               args:(va_list)argList;

+ (void)flushLog;

@end



#pragma mark - Loggers

@interface ZegoAbstructLogger : NSObject <ZegoLogger>

@property (assign, nonatomic) ZegoLogLevel level;
@property (strong, nonatomic, nullable) dispatch_queue_t logQueue;
@property (strong, nonatomic, nullable) id<ZegoLogFormatter> formatter;

- (void)zg_logMessage:(ZegoLogMessage *)message;
- (void)zg_flush;

@end


NS_ASSUME_NONNULL_END
