//
//  ZGMixStreamTopicHelper.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/23.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGMixStreamTopicHelper.h"

static NSString *ZGMixStreamTopicUserIDPrefix = @"u-";

@implementation ZGMixStreamTopicHelper

+ (unsigned int)getCurrentTimestamp {
    return (unsigned int)[NSDate date].timeIntervalSince1970;
}

+ (NSString *)assembleUserIDWithTimestamp:(unsigned int)timestamp {
    return [NSString stringWithFormat:@"%@%@", ZGMixStreamTopicUserIDPrefix, @(timestamp)];
}

+ (unsigned int)parseTimestampFromUserID:(NSString *)userID occurError:(BOOL *)occurError {
    
    NSRange range = [userID rangeOfString:ZGMixStreamTopicUserIDPrefix];
    if (range.location == 0) {
        NSString *timestamp = [userID stringByReplacingCharactersInRange:range withString:@""];
        NSString* numRegex = @"^[0-9]+$";
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", numRegex];
        if ([predicate evaluateWithObject:timestamp]) {
            NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
            f.numberStyle = NSNumberFormatterDecimalStyle;
            NSNumber *myNumber = [f numberFromString:timestamp];
            return [myNumber unsignedIntValue];
        }
    }
    
    if (occurError != NULL) {
        *occurError = YES;
    }
    return 0;
}

@end
