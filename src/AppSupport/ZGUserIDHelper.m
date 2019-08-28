//
//  ZGUserIDHelper.m
//  LiveRoomPlayground
//
//  Copyright © 2018年 Zego. All rights reserved.
//

#import "ZGUserIDHelper.h"
#import "ZGUserDefaults.h"

#if TARGET_OS_OSX
#import <IOKit/IOKitLib.h>
#elif TARGET_OS_IOS
#import <UIKit/UIKit.h>
#endif

NSString* kZGUserIDKey = @"user_id";

@interface ZGUserIDHelper ()

@end

static NSString *_userID = nil;

@implementation ZGUserIDHelper

+ (ZGUserDefaults *)myUserDefaults {
    return [[ZGUserDefaults alloc] init];
}

+ (NSString *)userID {
    if (_userID.length == 0) {
        NSUserDefaults *ud = [self myUserDefaults];
        NSString *userID = [ud stringForKey:kZGUserIDKey];
        if (userID.length > 0) {
            _userID = userID;
        }
        else {
            srand((unsigned)time(0));
            userID = [NSString stringWithFormat:@"%u", (unsigned)rand()];
            _userID = userID;
            [ud setObject:userID forKey:kZGUserIDKey];
            [ud synchronize];
        }
    }
    
    return _userID;
}

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
