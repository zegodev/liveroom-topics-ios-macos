//
//  ZegoRAMStoreLogger.m
//  Chatroom-iOS
//
//  Created by Sky on 2019/3/26.
//  Copyright © 2019 zego. All rights reserved.
//

#import "ZegoRAMStoreLogger.h"

NSString *ZegoRAMStoreLoggerLogDidChangeNotification = @"ZegoRAMStoreLoggerLogDidChangeNotification";

@interface ZegoRAMStoreLogger ()
@property (strong, atomic) NSMutableArray *logs;
@end

@implementation ZegoRAMStoreLogger

- (instancetype)init {
    if (self = [super init]) {
        _logs = [NSMutableArray array];
    }
    return self;
}

- (void)zg_logMessage:(ZegoLogMessage *)message {
    [_logs addObject:message];
    [NSNotificationCenter.defaultCenter postNotificationName:ZegoRAMStoreLoggerLogDidChangeNotification object:self];
}

- (void)zg_flush {
    [_logs removeAllObjects];
    [NSNotificationCenter.defaultCenter postNotificationName:ZegoRAMStoreLoggerLogDidChangeNotification object:self];
}

@end
