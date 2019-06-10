//
//  ZegoDefaultLogFormatter.m
//  Chatroom-iOS
//
//  Created by Sky on 2019/3/26.
//  Copyright © 2019 zego. All rights reserved.
//

#import "ZegoDefaultLogFormatter.h"
#import "ZegoLogMessage.h"

@implementation ZegoDefaultLogFormatter

- (NSString *)formatLogMessage:(ZegoLogMessage *)message {
    return message.message;
}

@end
