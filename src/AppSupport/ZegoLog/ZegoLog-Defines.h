//
//  ZegoLog-Defines.h
//  Chatroom-iOS
//
//  Created by Sky on 2019/3/26.
//  Copyright © 2019 zego. All rights reserved.
//

#ifndef ZegoLog_Defines_h
#define ZegoLog_Defines_h

#import <Foundation/Foundation.h>

#pragma mark - Defines

#define ZGLogError(frmt, ...)   ZGLOG_MACRO(kZegoLogFlagError,   __PRETTY_FUNCTION__, (frmt), ##__VA_ARGS__)
#define ZGLogWarn(frmt, ...)    ZGLOG_MACRO(kZegoLogFlagWarning, __PRETTY_FUNCTION__, (frmt), ##__VA_ARGS__)
#define ZGLogInfo(frmt, ...)    ZGLOG_MACRO(kZegoLogFlagInfo,    __PRETTY_FUNCTION__, (frmt), ##__VA_ARGS__)
#define ZGLogDebug(frmt, ...)   ZGLOG_MACRO(kZegoLogFlagDebug,   __PRETTY_FUNCTION__, (frmt), ##__VA_ARGS__)
#define ZGLogVerbose(frmt, ...) ZGLOG_MACRO(kZegoLogFlagVerbose, __PRETTY_FUNCTION__, (frmt), ##__VA_ARGS__)

#define ZGLOG_MACRO(flg, func, frmt, ...) \
[ZegoLog logWithFlag:flg \
file:__FILE__ \
function:func \
line:__LINE__ \
format:(frmt), ## __VA_ARGS__]

typedef NS_ENUM(NSUInteger, ZegoLogFlag) {
    kZegoLogFlagError = 1,
    kZegoLogFlagWarning = 1<<1,
    kZegoLogFlagInfo = 1<<2,
    kZegoLogFlagDebug = 1<<3,
    kZegoLogFlagVerbose = 1<<4,
};

typedef NS_ENUM(NSUInteger, ZegoLogLevel) {
    kZegoLogLevelError = kZegoLogFlagError,
    kZegoLogLevelWarn = (kZegoLogLevelError | kZegoLogFlagWarning),
    kZegoLogLevelInfo = (kZegoLogLevelWarn | kZegoLogFlagInfo),
    kZegoLogLevelDebug = (kZegoLogLevelInfo | kZegoLogFlagDebug),
    kZegoLogLevelVerbose = (kZegoLogLevelDebug | kZegoLogFlagVerbose),
};


@class ZegoLogMessage,ZegoAbstructLogger;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Protocol

@protocol ZegoLogFormatter <NSObject>
- (NSString *)formatLogMessage:(ZegoLogMessage *)message;
@end

@protocol ZegoLogger <NSObject>
@property (assign, nonatomic) ZegoLogLevel level;
@property (strong, nonatomic, nullable) dispatch_queue_t logQueue;
@property (strong, nonatomic, nullable) id<ZegoLogFormatter> formatter;
- (void)logMessage:(ZegoLogMessage *)message;
- (void)flush;
@optional
- (void)didAddLogger;
- (void)willRemoveLogger;
@end

NS_ASSUME_NONNULL_END

#endif /* ZegoLog_Defines_h */
