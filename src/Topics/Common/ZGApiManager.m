//
//  ZGApiManager.m
//  LiveRoomPlayground
//
//  Copyright © 2018年 Zego. All rights reserved.
//

#import "ZGApiManager.h"
#import "ZGKeyCenter.h"
#import "ZGApiSettingHelper.h"

static ZegoLiveRoomApi *s_apiInstance = nil;

@implementation ZGApiManager

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
        [self initApiWithAppID:self.appID appSign:self.appSign completionBlock:nil];
        
        NSString *userID = ZGHelper.userID;
        [ZegoLiveRoomApi setUserID:userID userName:userID];
    }
    
    return s_apiInstance;
}

/**
 * 释放zegoSDK
 * 当开发者不再需要使用到sdk时, 可以释放sdk。
 * 注意!!! 请根据业务需求来释放sdk。
 */
+ (void)releaseApi {
    ZGLogInfo(@"销毁SDK");
    s_apiInstance = nil;
}

+ (void)initApiWithAppID:(unsigned int)appID appSign:(NSData *)appSign completionBlock:(nullable ZegoInitSDKCompletionBlock)blk {
    if (s_apiInstance) {
        ZGLogInfo(@"初始化SDK，但已存在SDK实例");
        [self releaseApi];
    }
    
    //设置环境的接口需要在 SDK 初始化前调用才会生效
    //建议开发者在开发阶段设置为测试环境，使用由 ZEGO 提供的测试环境，上线前需切换为正式环境运营
    //注意!!! 如果没有向 ZEGO 申请正式环境的 AppID, 则需设置成测试环境, 否则 SDK 会初始化失败
//    [ZegoLiveRoomApi setUseTestEnv:testEnv ? true:false];
    [ZGApiSettingHelper.shared setSDKUseTestEnv:ZGApiSettingHelper.shared.useTestEnv];
    
    //AppID:Zego 分配的AppID, 可通过 https://console.zego.im/acount/login 申请
    //AppSign:Zego 分配的签名, 用来校验对应 AppID 的合法性。 可通过 https://console.zego.im/acount/login 申请
    s_apiInstance = [[ZegoLiveRoomApi alloc] initWithAppID:appID appSignature:appSign completionBlock:^(int errorCode) {
        //errorCode 非0 代表初始化sdk失败
        //具体错误码说明请查看 https://doc.zego.im/CN/308.html
        BOOL success = errorCode == 0;
        
        if (success) {
            ZGLogInfo(@"SDK初始化成功，缓存当前AppID/AppSign");
            [self saveValue:@(appID) forKey:NSStringFromSelector(@selector(appID))];
            [self saveValue:appSign forKey:NSStringFromSelector(@selector(appSign))];
        }
        else {
            ZGLogError(@"SDK初始化失败,errorCode:%d",errorCode);
        }
        
        if (blk) {
            blk(errorCode);
        }
    }];
    
    ZGLogInfo(@"初始化SDK，AppID:%u,AppSign:%@", appID, appSign);
}

+ (unsigned int)appID {
    unsigned int appID = 0;
    
    id savedAppID = [self savedValueForKey:NSStringFromSelector(@selector(appID))];
    if (savedAppID) {
        appID = [savedAppID unsignedIntValue];
    }
    else {
        appID = ZGKeyCenter.appID;
    }
    
    return appID;
}

+ (NSData *)appSign {
    NSData *appSign = nil;
    
    NSData *savedAppSign = [self savedValueForKey:NSStringFromSelector(@selector(appSign))];
    if (savedAppSign) {
        appSign = savedAppSign;
    }
    else {
        appSign = ZGKeyCenter.appSign;
    }
    
    return appSign;
}


@end

