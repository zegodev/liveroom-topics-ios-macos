//
//  ZGManager.m
//  LiveRoomPlayground
//
//  Copyright © 2018年 Zego. All rights reserved.
//

#import "ZGManager.h"
#import "ZGHelper.h"

// * -----
#import "ZGAppServiceConfig.h"
/**
 本示例不提供 ZGAppServiceConfig.h 需要用户自行实现，提供两个函数，如
 
 unsigned int GetAppID() {
    return 123456789;   // 从即构主页申请
 }
 
 NSData* GetAppSignKey() {
     Byte signkey[] = { // 从即构主页申请
        0x00,0x01,0x02,0x03,0xb2,0xf2,0x13,0x70,
        0x00,0x01,0x02,0x03,0xb2,0xf2,0x13,0x70,
        0x00,0x01,0x02,0x03,0xb2,0xf2,0x13,0x70,
        0x00,0x01,0x02,0x03,0xb2,0xf2,0x13,0x70,};
 
     NSData* sign = [NSData dataWithBytes:signkey length:32];
     return sign;
 }
 */


static ZegoLiveRoomApi *s_apiInstance = nil;

@implementation ZGManager

+ (void)enableExternalVideoCapture:(id<ZegoVideoCaptureFactory>)factory videoRenderer:(id<ZegoLiveApiRenderDelegate>)renderer {
    if (s_apiInstance) {
        [self releaseApi];
    }
    
    [ZegoExternalVideoCapture setVideoCaptureFactory:factory channelIndex:ZEGOAPI_CHN_MAIN];
    
    if (renderer) {
        [ZegoLiveRoomApi enableExternalRender:YES];
        [[self api] setRenderDelegate:renderer];
    } else {
        [ZegoLiveRoomApi enableExternalRender:NO];
    }
}

+ (ZegoLiveRoomApi*)api {
    if (!s_apiInstance) {
        [ZegoLiveRoomApi setUserID:[ZGHelper getDeviceUUID] userName:[ZGHelper getDeviceUUID]];
        uint32_t appid = GetAppID();
        NSData* sign = GetAppSignKey();
        s_apiInstance = [[ZegoLiveRoomApi alloc] initWithAppID:appid appSignature:sign];
    }
    
    return s_apiInstance;
}

+ (void)releaseApi {
    s_apiInstance = nil;
}

+ (unsigned int)appID {
    return GetAppID();
}

@end

