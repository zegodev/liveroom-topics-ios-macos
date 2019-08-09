//
//  ZGApiManager.h
//  LiveRoomPlayground
//
//  Copyright © 2018年 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_OSX
#import <ZegoLiveRoomOSX/ZegoLiveRoomApi.h>
#import <ZegoLiveRoomOSX/ZegoLiveRoomApi-Player.h>
#import <ZegoLiveRoomOSX/ZegoLiveRoomApi-Publisher.h>
#import <ZegoLiveRoomOSX/zego-api-external-video-capture-oc.h>
#import <ZegoLiveRoomOSX/ZegoVideoCapture.h>
#define ZGView NSView
#elif TARGET_OS_IOS
#import <ZegoLiveRoom/ZegoLiveRoomApi.h>
#import <ZegoLiveRoom/ZegoLiveRoomApi-Player.h>
#import <ZegoLiveRoom/ZegoLiveRoomApi-Publisher.h>
#import <ZegoLiveRoom/zego-api-external-video-capture-oc.h>
#import <ZegoLiveRoom/ZegoVideoCapture.h>
#define ZGView UIView
#endif


NS_ASSUME_NONNULL_BEGIN

/**
 Api初始化管理类
 */
@interface ZGApiManager : NSObject

@property (class, strong, nonatomic, readonly) ZegoLiveRoomApi *api;

@property (class, assign, nonatomic, readonly) unsigned int appID;
@property (class, strong, nonatomic, readonly) NSData * appSign;

+ (void)enableExternalVideoCapture:(id<ZegoVideoCaptureFactory> _Nullable)factory videoRenderer:(id<ZegoLiveApiRenderDelegate> _Nullable)renderer;

+ (void)releaseApi;

+ (BOOL)initApiWithAppID:(unsigned int)appID appSign:(NSData *)appSign completionBlock:(nullable ZegoInitSDKCompletionBlock)blk;

@end

NS_ASSUME_NONNULL_END

