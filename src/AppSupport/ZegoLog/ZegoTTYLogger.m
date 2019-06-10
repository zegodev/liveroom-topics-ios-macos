//
//  ZegoTTYLogger.m
//  Chatroom-iOS
//
//  Created by Sky on 2019/3/26.
//  Copyright © 2019 zego. All rights reserved.
//

#import "ZegoTTYLogger.h"
#import "ZegoTTYLogFormatter.h"

@implementation ZegoTTYLogger

- (instancetype)init {
    if (self = [super init]) {
        self.formatter = [ZegoTTYLogFormatter new];
    }
    return self;
}

- (void)zg_logMessage:(ZegoLogMessage *)message {
    NSString *formattedMsg = [self.formatter formatLogMessage:message];
    const char *msg = formattedMsg.UTF8String;
    printf("%s\n", msg);
}

- (void)flush {}

@end
