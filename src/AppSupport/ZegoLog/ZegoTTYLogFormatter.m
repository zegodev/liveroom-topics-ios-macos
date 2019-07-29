//
//  ZegoTTYLogFormatter.m
//  Chatroom-iOS
//
//  Created by Sky on 2019/3/26.
//  Copyright © 2019 zego. All rights reserved.
//

#import "ZegoTTYLogFormatter.h"
#import "ZegoLogMessage.h"

@interface ZegoTTYLogFormatter ()
@property (class, strong, nonatomic) NSDateFormatter *dateFormatter;
@end

NSDateFormatter *_zg_tty_dateFormatter = nil;

@implementation ZegoTTYLogFormatter

+ (void)initialize {
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateFormat = @"HH:mm:ss.SSS";
}

- (NSString *)formatLogMessage:(ZegoLogMessage *)message {
    NSString *prefix = nil;
    switch (message.flag) {
        case kZegoLogFlagError:
            prefix = @"🔴";
            break;
        case kZegoLogFlagWarning:
            prefix = @"🔶";
            break;
        case kZegoLogFlagInfo:
            prefix = @"🔷";
            break;
        case kZegoLogFlagDebug:
            prefix = @"◽️";
            break;
        case kZegoLogFlagVerbose:
            prefix = @"◾️";
            break;
    }
    
    NSString *formattedMsg = [NSString stringWithFormat:@"[%@]:%@ %@",
                              [ZegoTTYLogFormatter.dateFormatter stringFromDate:message.date],
                              prefix,
                              message.message];
    
    return formattedMsg;
}

+ (NSDateFormatter *)dateFormatter {
    return _zg_tty_dateFormatter;
}

+ (void)setDateFormatter:(NSDateFormatter *)dateFormatter {
    _zg_tty_dateFormatter = dateFormatter;
}

@end
