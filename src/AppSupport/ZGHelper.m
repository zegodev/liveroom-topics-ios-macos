//
//  ZGHelper.m
//  LiveRoomPlayground
//
//  Copyright © 2018年 Zego. All rights reserved.
//

#import "ZGHelper.h"

#if TARGET_OS_OSX
#import <IOKit/IOKitLib.h>
#elif TARGET_OS_IOS
#import <UIKit/UIKit.h>
#endif

NSString* kZGTopicMediaPlayer = @"Media Player";
NSString* kZGTopicMediaSideInfo = @"Media Side Info";

@implementation ZGHelper

#if TARGET_OS_OSX
+ (NSString *)getDeviceUUID {
    io_service_t platformExpert;
    platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"));
    if (platformExpert) {
        CFTypeRef serialNumberAsCFString;
        serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, CFSTR("IOPlatformUUID"), kCFAllocatorDefault, 0);
        IOObjectRelease(platformExpert);
        if (serialNumberAsCFString) {
            return (__bridge_transfer NSString*)(serialNumberAsCFString);
        }
    }
    
    return @"hello";
}
#elif TARGET_OS_IOS
+ (NSString *)getDeviceUUID {
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}
#endif
@end
