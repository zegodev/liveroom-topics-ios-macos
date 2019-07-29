//
//  ZegoDiskLogFormatter.m
//  Chatroom-iOS
//
//  Created by Sky on 2019/3/26.
//  Copyright © 2019 zego. All rights reserved.
//

#import "ZegoDiskLogFormatter.h"
#import "ZegoLogMessage.h"

@interface ZegoDiskLogFormatter ()
@property (class, strong, nonatomic) NSDateFormatter *dateFormatter;
@end

NSDateFormatter *_zg_disk_dateFormatter = nil;

@implementation ZegoDiskLogFormatter

+ (void)initialize {
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateFormat = @"MM-dd HH:mm:ss.SSS";
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
    
    NSString *formattedMsg = [NSString stringWithFormat:@"[%@]:%@ %@        file:%@,line:%lu\n",
                              [ZegoDiskLogFormatter.dateFormatter stringFromDate:message.date],
                              prefix,
                              message.message,
                              message.fileName.lastPathComponent,
                              (unsigned long)message.line];
    
    return formattedMsg;
}

+ (NSDateFormatter *)dateFormatter {
    return _zg_disk_dateFormatter;
}

+ (void)setDateFormatter:(NSDateFormatter *)dateFormatter {
    _zg_disk_dateFormatter = dateFormatter;
}

@end
