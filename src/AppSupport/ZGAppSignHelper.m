//
//  ZGAppSignHelper.m
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/8/6.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGAppSignHelper.h"

@implementation ZGAppSignHelper

static NSString *mapString = @"0123456789abcdef";

+ (NSData *)convertAppSignFromString:(NSString *)appSignString {
    if(appSignString == nil || appSignString.length == 0) {
        return nil;
    }
    
    appSignString = [appSignString lowercaseString];
    appSignString = [appSignString stringByReplacingOccurrencesOfString:@" " withString:@""];
    appSignString = [appSignString stringByReplacingOccurrencesOfString:@"0x" withString:@""];
    NSArray<NSString *>* bytes = [appSignString componentsSeparatedByString:@","];
    
    Byte sign[32];
    int bytesLen = (int)[bytes count];
    
    for(int i = 0; i < bytesLen; i++) {
        NSString *byteStr = [bytes objectAtIndex:i];
        
        if (byteStr.length == 1) {
            sign[i] = [self convertByteStringToByte:byteStr];
        }
        else if (byteStr.length == 2) {
            Byte highByte = [self convertByteStringToByte:[byteStr substringWithRange:NSMakeRange(0, 1)]];
            Byte lowByte = [self convertByteStringToByte:[byteStr substringWithRange:NSMakeRange(1, 1)]];
            sign[i] = highByte<<4 | lowByte;
        }
        else {
            sign[i] = 0;
        }
    }
    
    NSData *signData = [NSData dataWithBytes:sign length:32];
    return signData;
}

+ (NSString *)convertAppSignToString:(NSData *)appSignData {
    if (!appSignData) {
        return nil;
    }
    
    NSMutableString *signString = [NSMutableString string];
    Byte *bytes = (Byte*)appSignData.bytes;
    for (int i = 0; i < appSignData.length; ++i) {
        Byte b = bytes[i];
        NSString *byteString = [self convertByteToByteString:b];
        [signString appendString:byteString];
        if (i != appSignData.length-1) {
            [signString appendString:@","];
        }
    }
    return signString;
}

+ (Byte)convertByteStringToByte:(NSString *)byteString {
    Byte b = [mapString rangeOfString:byteString].location;
    return b;
}

+ (NSString *)convertByteToByteString:(Byte)b {
    NSString *highByteStr = [mapString substringWithRange:NSMakeRange((NSUInteger)(b>>4), 1)];
    NSString *lowByteStr = [mapString substringWithRange:NSMakeRange((NSUInteger)(b&0x0f), 1)];
    return [NSString stringWithFormat:@"0x%@%@",highByteStr,lowByteStr];
}

@end
